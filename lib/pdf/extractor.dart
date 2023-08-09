import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:jni/jni.dart';
import 'package:lazyext/src/third_party/com/artifex/mupdf/fitz/_package.dart'
    as mupdf;
import 'package:path_provider/path_provider.dart';

typedef ExerciseCollection = (String, List<Exercise>);
typedef ExerciseBound = (int, double);

class Exercise {
  ExerciseBound start;
  ExerciseBound? end;
  Image? image;

  Exercise({required this.start, this.end, this.image});

  Exercise copyWith() {
    return Exercise(start: start, end: end, image: image);
  }
}

class ExerciseExtractor {
  RegExp exerciseRegex = RegExp(r"^[1-9]\d*\.");
  double offsetStart = -10;
  double offsetEnd = -5;

  Future<Image?> _pixmapToImage(mupdf.Pixmap pixmap) async {
    String? path = (await getTemporaryDirectory()).path;
    pixmap.saveAsPNG("$path/output.png".toJString());
    return decodePngFile("$path/output.png");
  }

  Future<Image?> _pageRectToImage(mupdf.Page page, mupdf.Rect rect) async {
    mupdf.Pixmap pixmap =
        mupdf.Pixmap.ctor4(mupdf.ColorSpace.DeviceRGB, rect, true);
    mupdf.DrawDevice device = mupdf.DrawDevice.ctor2(pixmap);
    page.run(device, mupdf.Matrix.Identity(), mupdf.Cookie());
    return _pixmapToImage(pixmap);
  }

  List<T> _jArrayToList<T extends JObject>(JArray<T> list) {
    List<T> elems = [];
    for (int j = 0; j < list.length; j++) {
      elems.add(list[j]);
    }
    return elems;
  }

  List<mupdf.StructuredText_TextLine> _getLinesOnPage(mupdf.Page page) {
    List<mupdf.StructuredText_TextBlock> blocks = _jArrayToList(
        page.toStructuredText("preserve-whitespaces".toJString()).getBlocks());
    List<mupdf.StructuredText_TextLine> lines = [];
    for (mupdf.StructuredText_TextBlock block in blocks) {
      lines.addAll(_jArrayToList(block.lines));
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

  mupdf.Rect _pageToRect(mupdf.Page page) {
    return _boundsToRect(page, page.getBounds().y0, page.getBounds().y1);
  }

  mupdf.Rect _boundsToRect(mupdf.Page page, double start, double end) {
    return mupdf.Rect.ctor1(0, start, page.getBounds().x1, end);
  }

  double _getPageTop(mupdf.Page page) {
    return _getLinesOnPage(page).first.bbox.y0;
  }

  double _getLowestLine(List<mupdf.StructuredText_TextLine> lines) {
    double lowest = 0;
    for (mupdf.StructuredText_TextLine line in lines) {
      if (lowest < line.bbox.y1) {
        lowest = line.bbox.y1;
      }
    }
    return lowest;
  }

  double _getPageBottom(mupdf.Page page) {
    //return page.getBounds().y1;
    //return _getLowestLine(_getLinesOnPage(page));
  }

  List<(mupdf.Page, mupdf.Rect)> _exerciseToRects(
      mupdf.Document document, Exercise exercise) {
    final ExerciseBound start = exercise.start;
    ExerciseBound? end = exercise.end;
    List<(mupdf.Page, mupdf.Rect)> rects = [];
    if (end != null) {
      if (start.$1 == end.$1) {
        mupdf.Page page = document.loadPage(start.$1, start.$1);
        rects.add((page, _boundsToRect(page, start.$2, end.$2)));
      } else {
        for (int i = start.$1; i <= end.$1; i++) {
          mupdf.Page page = document.loadPage(i, i);
          mupdf.Rect rect;
          if (i == start.$1) {
            rect = _boundsToRect(page, start.$2, _getPageBottom(page));
          } else if (i == end.$1) {
            rect = _boundsToRect(page, _getPageTop(page), end.$2);
          } else {
            rect = _pageToRect(page);
          }
          rects.add((page, rect));
        }
      }
    }
    return rects;
  }

  int _getBiggestImageWidth(List<Image> images) {
    int biggest = 0;
    for (Image image in images) {
      biggest = max(biggest, image.width);
    }
    return biggest;
  }

  int _getBiggestImageHeight(List<Image> images) {
    int biggest = 0;
    for (Image image in images) {
      biggest = max(biggest, image.height);
    }
    return biggest;
  }

  Image _stitchImages(List<Image> images) {
    Image finalImage = Image(
        width: _getBiggestImageWidth(images),
        height: _getBiggestImageHeight(images));
    int current = 0;
    for (Image image in images) {
      compositeImage(finalImage, image, dstY: current);
      current += image.height;
    }
    return finalImage;
  }

  Exercise _offsetExercise(Exercise exercise,
      {bool first = false, bool last = false}) {
    exercise.start =
        (exercise.start.$1, exercise.start.$2 + (first ? 0 : offsetStart));
    ExerciseBound? end = exercise.end;
    if (end != null) {
      exercise.end = (end.$1, end.$2 + (last ? 0 : offsetEnd));
    }
    return exercise;
  }

  Future<Exercise> _exerciseToImage(
      Exercise prev, mupdf.Document document) async {
    List<Image> images = [];
    for ((mupdf.Page, mupdf.Rect) rect in _exerciseToRects(document, prev)) {
      Image? image = await _pageRectToImage(rect.$1, rect.$2);
      if (image != null) {
        images.add(image);
      }
    }
    if (images.length == 1) {
      prev.image = images.first;
    } else if (images.length > 1) {
      prev.image = _stitchImages(images);
    }
    return prev;
  }

  Future<List<Exercise>> _extractExercises(mupdf.Document document) async {
    List<Exercise> exercises = [];
    Exercise? prev;
    for (int i = 0; i < document.countPages(0); i++) {
      mupdf.Page page = document.loadPage(i, i);
      List<mupdf.StructuredText_TextLine> lines = _getLinesOnPage(page);
      bool isFirst = true;
      for (mupdf.StructuredText_TextLine line in lines) {
        String text = _charsToText(line.chars);
        if (exerciseRegex.hasMatch(text)) {
          if (prev != null) {
            prev.end = (i, line.bbox.y0);
            prev = _offsetExercise(prev, first: isFirst);
            isFirst = false;
            prev = await _exerciseToImage(prev, document);
            exercises.add(prev.copyWith());
          }
          prev = Exercise(start: (i, line.bbox.y0));
        }
      }
      if (prev != null) {
        prev.end = (i, _getPageBottom(page));
        if (i + 1 == document.countPages(0)) {
          prev = _offsetExercise(prev, last: true);
          prev = await _exerciseToImage(prev, document);
          exercises.add(prev.copyWith());
        }
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
