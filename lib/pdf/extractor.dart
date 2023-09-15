import 'package:jni/jni.dart';
import 'package:mupdf_android/mupdf_android.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'mapper.dart';

abstract class Extractor {
  Future<PDFDocument?> exercisesToDocument(List<Exercise> exercises);
}

class PracticeExtractor implements Extractor {
  /*void _putPatternOnBuffer(Buffer buffer, Rect pageSize, {double y = 0}) {
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
  }*/

  void _drawLine(Device device, Point a, Point b) {
    JArray<jfloat> colors = JArray(jfloat.type, 4);
    colors[0] = 0;
    colors[1] = 0;
    colors[2] = 0;
    colors[3] = 1;
    double size = 1;
    Path path = Path();
    path.moveTo(a.x, a.y);
    path.lineTo(b.x, b.y);
    device.strokePath(
        path,
        StrokeState(size.toInt(), size.toInt(), size.toInt(), size, size),
        Matrix.Identity(),
        ColorSpace.DeviceRGB,
        colors,
        1,
        1);
  }

  void _drawPattern(Device device, Rect pageSize, {double y = 0}) {
    double spacing = 20;
    double x = 0;
    while (x <= pageSize.x1) {
      _drawLine(device, Point(x, y), Point(x, pageSize.y1));
      x += spacing;
    }
    while (y <= pageSize.y1) {
      _drawLine(device, Point(0, y), Point(pageSize.x1, y));
      y += spacing;
    }
  }

  @override
  Future<PDFDocument?> exercisesToDocument(List<Exercise> exercises) async {
    String path =
        "${(await getTemporaryDirectory()).path}/${const Uuid().v4()}";
    Rect a4 = MuPDF.MEDIABOXES["A4"] ?? Rect.new1(0, 0, 595, 842);
    RectDevice device = RectDevice.new2(path.toJString());
    for (Exercise exercise in exercises) {
      if (exercise.start.$1 == exercise.end!.$1) {
        device.beginPage();
        exercise.document.pages[exercise.start.$1].run(
            device.filterDevice(
                Rect.new1(0, exercise.start.$2, a4.x1, exercise.end!.$2)),
            Matrix.Identity(),
            Cookie());
        _drawPattern(device.current, a4);
        device.endPage();
      }
    }
    device.done();
    return Document.openDocument(path.toJString()).toPDFDocument();
  }
}

/*class SummaryMerger implements Extractor {
  @override
  Future<PDFDocument> exercisesToFile(List<Exercise> exercises) async {
    PDFDocument document = PDFDocument.new1();
    double offset = 0;
    Rect a4 = MuPDF.MEDIABOXES["A4"] ?? Rect.new1(0, 0, 595, 842);
    Buffer buffer = Buffer.new1();
    PDFObject imageDict = document.newDictionary();
    for (Exercise exercise in exercises) {
      img.Image? image = exercise.image;
      if (image != null) {
        offset += image.height;
        if (offset > a4.y1) {
          PDFObject resources = document.newDictionary();
          resources.put9("XObject".toJString(), imageDict);
          document.insertPage(-1, document.addPage(a4, 0, resources, buffer));
          buffer = Buffer.new1();
          offset = 0;
        }
        await _putExerciseImageOnBuffer(buffer, imageDict, document, a4, image,
            offset: offset);
      }
    }
    PDFObject resources = document.newDictionary();
    resources.put9("XObject".toJString(), imageDict);
    document.insertPage(-1, document.addPage(a4, 0, resources, buffer));
    return document;
  }
}*/
