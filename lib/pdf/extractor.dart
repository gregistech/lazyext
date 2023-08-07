import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jni/jni.dart';
import 'package:lazyext/src/third_party/com/artifex/mupdf/fitz/_package.dart'
    as mupdf;
import 'package:path_provider/path_provider.dart';

typedef ExerciseCollection = (String, List<Exercise>);

class Exercise {
  mupdf.Rect bounds;
  ImageProvider? image;

  Exercise({required this.bounds, this.image});

  Exercise copyWith() {
    return Exercise(bounds: bounds, image: image);
  }
}

class ExerciseExtractor {
  RegExp exerciseRegex = RegExp(r"^[1-9]\d*\.");
  mupdf.Rect offset = mupdf.Rect.ctor1(0, -7.5, 0, 0);

  Future<ImageProvider> _pageRectToImage(
      mupdf.Page page, mupdf.Rect rect) async {
    mupdf.Pixmap pixmap =
        mupdf.Pixmap.ctor4(mupdf.ColorSpace.DeviceRGB, rect, true);
    mupdf.DrawDevice device = mupdf.DrawDevice.ctor2(pixmap);
    page.run(device, mupdf.Matrix.Identity(), mupdf.Cookie());
    String path = (await getTemporaryDirectory()).path;
    pixmap.saveAsPNG("$path/output.png".toJString());
    return MemoryImage(await File("$path/output.png").readAsBytes());
  }

  List<mupdf.StructuredText_TextLine> _getLinesOnPage(mupdf.Page page) {
    List<mupdf.StructuredText_TextLine> lines = [];
    mupdf.StructuredText text =
        page.toStructuredText("preserve-whitespaces".toJString());
    JArray<mupdf.StructuredText_TextBlock> blocks = text.getBlocks();
    for (int j = 0; j < blocks.length; j++) {
      mupdf.StructuredText_TextBlock block = blocks[j];
      for (int i = 0; i < block.lines.length; i++) {
        lines.add(block.lines[i]);
      }
    }
    return lines;
  }

  String _charsToText(JArray<mupdf.StructuredText_TextChar> chars) {
    String text = "";
    for (int i = 0; i < chars.length; i++) {
      text += String.fromCharCode(chars[i].c);
    }
    return text;
  }

  Future<Exercise> _updateExercise(
      Exercise prev, mupdf.Page page, double y) async {
    prev.bounds = mupdf.Rect.ctor1(0 + offset.x0, prev.bounds.y0 + offset.y0,
        page.getBounds().x1 + offset.x1, y + offset.y1);
    prev.image = await _pageRectToImage(page, prev.bounds);
    return prev;
  }

  Future<List<Exercise>> _extractExercises(mupdf.Document document) async {
    List<Exercise> exercises = [];
    for (int i = 0; i < document.countPages(i); i++) {
      mupdf.Page page = document.loadPage(i, i);
      List<mupdf.StructuredText_TextLine> lines = _getLinesOnPage(page);
      Exercise? prev;
      for (mupdf.StructuredText_TextLine line in lines) {
        String text = _charsToText(line.chars);
        if (exerciseRegex.hasMatch(text)) {
          if (prev != null) {
            prev = await _updateExercise(prev, page, line.bbox.y0);
            exercises.add(prev.copyWith());
          }
          prev = Exercise(bounds: line.bbox);
        }
      }
      if (prev != null) {
        prev = await _updateExercise(prev, page, lines.last.bbox.y1);
        exercises.add(prev.copyWith());
      }
    }
    return exercises;
  }

  String? _getDocumentTitle(mupdf.Document document) {
    return document
        .getMetaData("info:Title".toJString())
        .toDartString(deleteOriginal: true);
  }

  Future<ExerciseCollection> getExerciseCollection(File file) async {
    mupdf.Document document =
        mupdf.Document.openDocument(file.path.toJString());
    String title = _getDocumentTitle(document) ?? "PLACEHOLDER";
    List<Exercise> exercises = await _extractExercises(document);
    return (title, exercises);
  }
}
