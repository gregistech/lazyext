import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

typedef ExerciseCollection = (String, List<Exercise>);

class Exercise {
  Rect bounds;
  ImageProvider? image;

  Exercise({required this.bounds, this.image});

  Exercise copyWith() {
    return Exercise(bounds: bounds, image: image);
  }
}

class ExerciseExtractor {
  RegExp exerciseRegex = RegExp(r"^[1-9]\d*\.");

  Future<ImageProvider?> _pdfRectToImage(
      File file, int pageIndex, Rect rect) async {
    pdfx.PdfDocument document = await pdfx.PdfDocument.openFile(file.path);
    pdfx.PdfPage page = await document.getPage(pageIndex + 1);
    pdfx.PdfPageImage? pageImage = await page.render(
        width: page.width, height: page.height, cropRect: rect);
    page.close();
    document.close();
    if (pageImage != null) {
      return MemoryImage(pageImage.bytes);
    } else {
      return null;
    }
  }

  Future<List<Exercise>> _extractExercises(
      PdfDocument document, File file) async {
    List<Exercise> exercises = [];
    for (int i = 0; i < document.pages.count; i++) {
      List<TextLine> lines =
          PdfTextExtractor(document).extractTextLines(startPageIndex: i);
      Exercise? prev;
      TextLine? lastLine;
      for (TextLine line in lines) {
        if (exerciseRegex.hasMatch(line.text)) {
          if (prev == null) {
            prev = Exercise(bounds: line.bounds);
          } else {
            prev.bounds = Rect.fromLTRB(0, prev.bounds.top,
                document.pages[i].size.width, line.bounds.top);
            ImageProvider? image = await _pdfRectToImage(file, i, prev.bounds);
            if (image != null) {
              prev.image = image;
            }
            exercises.add(prev.copyWith());
            prev = Exercise(bounds: line.bounds);
          }
        }
        lastLine = line;
      }
      Exercise? last = prev;
      if (last != null && lastLine != null) {
        last.bounds = Rect.fromLTRB(0, last.bounds.top,
            document.pages[i].size.width, lastLine.bounds.bottom);
        ImageProvider? image = await _pdfRectToImage(file, i, last.bounds);
        if (image != null) {
          last.image = image;
        }
        exercises.add(last);
      }
    }
    return exercises;
  }

  String? _getVisualTitle(PdfDocument document) {
    //throw UnimplementedError();
    return null;
  }

  Future<ExerciseCollection> getExerciseCollection(File file) async {
    PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());

    return (
      _getVisualTitle(document) ?? document.documentInformation.title,
      await _extractExercises(document, file)
    );
  }
}
