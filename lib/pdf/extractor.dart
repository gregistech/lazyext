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
    RectDevice rectDevice =
        await ExerciseCopier(this.document.pages.first.getBounds1()).device;
    rectDevice.beginPage();
    Rect bounds = rectDevice.runExercise(this);
    rectDevice.endPage();
    Document document = Document.openDocument(rectDevice.done());
    return document.pages.first.rectToPixmap(bounds);
  }
}

extension Run on RectDevice {
  Rect runExercise(Exercise exercise,
      {double? y, Rect? pageSize, double margin = 0}) {
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
      page.run1(filterDevice(page, filter, y ?? 0 + offset), Matrix.Identity());
    }
    return Rect.new1(0, 0 + margin, pageSize.x1, lowest);
  }
}

class ExerciseCopier {
  Rect pageSize;
  ExerciseCopier(this.pageSize);

  Future<RectDevice> get device async => RectDevice.new2(
      "${(await getTemporaryDirectory()).path}/${const Uuid().v4()}.pdf"
          .toJString(),
      pageSize);
}

mixin PDFDraw {
  void drawLine(Device device, Point a, Point b,
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

  void drawCheckerboardPattern(Device device, Rect pageSize, {double y = 0}) {
    double spacing = 20;
    double x = 0;
    while (x <= pageSize.x1) {
      drawLine(device, Point(x, y), Point(x, pageSize.y1));
      x += spacing;
    }
    while (y <= pageSize.y1) {
      drawLine(device, Point(0, y), Point(pageSize.x1, y));
      y += spacing;
    }
  }
}

class PracticeExtractor extends ExerciseCopier
    with PDFDraw
    implements Extractor {
  PracticeExtractor(super.pageSize);

  @override
  Future<PDFDocument?> exercisesToDocument(List<Exercise> exercises) async {
    RectDevice rectDevice = await device;
    double margin = 20;
    for (Exercise exercise in exercises) {
      rectDevice.beginPage();
      rectDevice.runExercise(exercise, margin: margin);
      drawCheckerboardPattern(rectDevice.current, pageSize,
          y: rectDevice.lowest + margin);
      rectDevice.endPage();
    }
    return Document.openDocument(rectDevice.done()).toPDFDocument();
  }
}

class SummaryExtractor extends ExerciseCopier
    with PDFDraw
    implements Extractor {
  SummaryExtractor(super.pageSize);

  @override
  Future<PDFDocument?> exercisesToDocument(List<Exercise> exercises) async {
    double margin = 20;
    RectDevice rectDevice = await device;
    double y = 0;
    rectDevice.beginPage();
    for (Exercise exercise in exercises) {
      print(y + (exercise.end!.$2 - exercise.start.$1));
      if (y + (exercise.end!.$2 - exercise.start.$1) > pageSize.y1) {
        rectDevice.endPage();
        rectDevice.beginPage();
        y = 0;
      }
      y += rectDevice.runExercise(exercise, margin: margin, y: y).y1;
      drawLine(rectDevice.current, Point(0, y), Point(pageSize.x1, y));
    }
    rectDevice.endPage();
    return Document.openDocument(rectDevice.done()).toPDFDocument();
  }
}
