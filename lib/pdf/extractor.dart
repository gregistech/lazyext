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

  Future<List<Exercise>> _extractExercises(mupdf.Document document) async {
    List<Exercise> exercises = [];
    for (int i = 0; i < document.countPages(i); i++) {
      mupdf.Page page = document.loadPage(i, i);
      List<mupdf.StructuredText_TextLine> lines = _getLinesOnPage(page);
      Exercise? prev;
      mupdf.Rect? lastBounds;
      for (final line in lines) {
        String text = _charsToText(line.chars);
        if (exerciseRegex.hasMatch(text)) {
          print(
              "$text: ${line.bbox.x0}, ${line.bbox.y0}, ${line.bbox.x1}, ${line.bbox.y1}");
          if (prev == null) {
            prev = Exercise(bounds: line.bbox);
          } else {
            prev.bounds = mupdf.Rect.ctor1(
                0, prev.bounds.y0, page.getBounds().x1, line.bbox.y0);
            prev.image = await _pageRectToImage(page, prev.bounds);
            exercises.add(prev.copyWith());
            prev = Exercise(bounds: line.bbox);
          }
        }
        lastBounds = line.bbox;
      }
      Exercise? last = prev;
      if (last != null && lastBounds != null) {
        last.bounds = mupdf.Rect.ctor1(
            0, last.bounds.y0, page.getBounds().x1, lastBounds.y1);
        last.image = await _pageRectToImage(page, last.bounds);
        exercises.add(last);
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
