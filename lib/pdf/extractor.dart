import 'package:jni/jni.dart';
import 'package:mupdf_android/mupdf_android.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'mapper.dart';

abstract class Extractor {
  Future<PDFDocument?> exercisesToDocument(List<Exercise> exercises);
}

extension ToPixmap on Exercise {
  Future<Pixmap> toPixmap() async {
    RectDevice rectDevice = await ExerciseCopier().device;
    rectDevice.beginPage();
    Rect bounds = rectDevice.runExercise(this);
    rectDevice.endPage();
    Document document = Document.openDocument(rectDevice.done());
    return document.pages.first.rectToPixmap(bounds);
  }
}

extension Run on RectDevice {
  Rect runExercise(Exercise exercise, {Rect? pageSize, double margin = 20}) {
    pageSize ??= MuPDF.MEDIABOXES["A4"] ?? Rect.new1(0, 0, 595, 842);
    List<Page> pages = exercise.document.pages
        .sublist(exercise.start.$1, exercise.end!.$1 + 1);
    for (int i = 0; i < pages.length; i++) {
      Page page = pages[i];
      double start = exercise.start.$2;
      double end = exercise.end!.$2;
      double offset = margin;
      if (exercise.start.$1 != exercise.end!.$1) {
        if (exercise.end!.$1 == i) {
          start = 0;
          end = exercise.end!.$2;
          offset = lowest;
        } else if (i == 0) {
          end = pageSize.y1;
        } else {
          start = 0;
          end = pageSize.y1;
          offset = 0;
        }
      }
      Rect filter = Rect.new1(0, start, pageSize.x1, end);
      FindHighestInRectDevice finder = FindHighestInRectDevice();
      page.run(finder.filterDevice(filter), Matrix.Identity(), Cookie());
      page.run(filterDevice(filter, finder.highest - offset), Matrix.Identity(),
          Cookie());
    }
    return Rect.new1(0, 0 + margin, pageSize.x1, lowest);
  }
}

class ExerciseCopier {
  Future<RectDevice> get device async => RectDevice.new2(
      "${(await getTemporaryDirectory()).path}/${const Uuid().v4()}.pdf"
          .toJString());
}

class PracticeExtractor extends ExerciseCopier implements Extractor {
  void _drawLine(Device device, Point a, Point b,
      {JArray<jfloat>? colors, double size = 1}) {
    if (colors == null) {
      colors = JArray(jfloat.type, 4);
      colors[0] = 0;
      colors[1] = 0;
      colors[2] = 0;
      colors[3] = 1;
    }
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
    Rect a4 = MuPDF.MEDIABOXES["A4"] ?? Rect.new1(0, 0, 595, 842);
    RectDevice rectDevice = await device;
    for (Exercise exercise in exercises) {
      rectDevice.beginPage();
      rectDevice.runExercise(exercise);
      _drawPattern(rectDevice.current, a4, y: rectDevice.lowest + 20);
      rectDevice.endPage();
    }
    return Document.openDocument(rectDevice.done()).toPDFDocument();
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
