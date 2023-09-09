import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:jni/jni.dart';
import 'package:mupdf_android/mupdf_android.dart';
import 'package:path_provider/path_provider.dart';

import 'extractor.dart';

abstract class Merger {
  Future<PDFDocument> exercisesToPDFDocument(List<Exercise> exercises);
}

mixin ImageMerger {
  Future<PDFObject> _putExerciseImageOnBuffer(
      Buffer buffer, PDFDocument document, Rect pageSize, img.Image image,
      {double offset = 0}) async {
    String path = "${(await getTemporaryDirectory()).path}/current.png";
    File file = File(path);
    await file.writeAsBytes(img.encodePng(image));
    PDFObject pdfImage = document.addImage(Image.new2(file.path.toJString()));
    PDFObject imageDict = document.newDictionary();
    imageDict.put9("Exercise".toJString(), pdfImage);
    double scale = (pageSize.x1 / image.width);
    double x = (pageSize.x1 - (image.width)) / 2;
    double y = pageSize.y1 - image.height - offset;
    buffer.writeLine(
        "q ${scale * image.width} 0 0 ${scale * image.height} $x $y cm /Exercise Do Q"
            .toJString());
    return imageDict;
  }
}

class PracticeMerger with ImageMerger implements Merger {
  void _putPatternOnBuffer(Buffer buffer, Rect pageSize, {double y = 0}) {
    double spacing = 20;
    double x = 0;
    for (int i = 0; i < pageSize.x1 / spacing; i++) {
      buffer.writeLine("q $x 0 m $x ${pageSize.y1} l h S Q".toJString());
      x += spacing;
    }
    for (int i = 0; i < pageSize.y1 / spacing; i++) {
      buffer.writeLine("q 0 $y m ${pageSize.x1} $y l h S Q".toJString());
      y -= spacing;
    }
  }

  @override
  Future<PDFDocument> exercisesToPDFDocument(List<Exercise> exercises) async {
    PDFDocument document = PDFDocument.new1();
    for (Exercise exercise in exercises) {
      img.Image? image = exercise.image;
      if (image != null) {
        Buffer buffer = Buffer.new1();
        PDFObject resources = document.newDictionary();
        Rect a4 = MuPDF.MEDIABOXES["A4"] ?? Rect.new1(0, 0, 595, 842);
        _putPatternOnBuffer(buffer, a4, y: a4.y1 - image.height);
        resources.put9("XObject".toJString(),
            await _putExerciseImageOnBuffer(buffer, document, a4, image));
        PDFObject page = document.addPage(a4, 0, resources, buffer);
        document.insertPage(-1, page);
      }
    }
    return document;
  }
}

class SummaryMerger with ImageMerger implements Merger {
  @override
  Future<PDFDocument> exercisesToPDFDocument(List<Exercise> exercises) async {
    PDFDocument document = PDFDocument.new1();
    double offset = 0;
    for (Exercise exercise in exercises) {
      img.Image? image = exercise.image;
      if (image != null) {
        Buffer buffer = Buffer.new1();
        PDFObject resources = document.newDictionary();
        Rect a4 = MuPDF.MEDIABOXES["A4"] ?? Rect.new1(0, 0, 595, 842);
        resources.put9(
            "XObject".toJString(),
            await _putExerciseImageOnBuffer(buffer, document, a4, image,
                offset: offset));
        offset += image.height;
        PDFObject page = document.addPage(a4, 0, resources, buffer);
        document.insertPage(-1, page);
      }
    }
    return document;
  }
}
