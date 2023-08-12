import 'package:jni/jni.dart';
import 'package:lazyext/src/third_party/com/gergovari/mupdf/_package.dart';

import '../src/third_party/com/artifex/mupdf/fitz/_package.dart';

class Bounder {
  Rect bbox = Rect.ctor1(
      double.infinity, double.infinity, double.infinity, double.infinity);

  Rect extend(double x, double y) {
    if (x < bbox.x0) {
      bbox.x0 = x;
    }
    if (x > bbox.x1) {
      bbox.x1 = x;
    }
    if (y < bbox.y0) {
      bbox.y0 = y;
    }
    if (y > bbox.y1) {
      bbox.y1 = y;
    }
    return bbox;
  }

  Rect extendPoint(Matrix m, double px, double py) {
    double x = px * m.a + py * m.c + m.e;
    double y = px * m.b + py * m.d + m.f;
    return extend(x, y);
  }

  Rect extendRect(Matrix m, Rect r) {
    bbox = extendPoint(m, r.x0, r.y0);
    bbox = extendPoint(m, r.x1, r.y0);
    bbox = extendPoint(m, r.x0, r.y1);
    bbox = extendPoint(m, r.x1, r.y1);
    return bbox;
  }
}

class PathBounder {
  final Bounder _bounder;
  final Matrix _matrix;

  PathBounder(this._bounder, this._matrix);

  void _moveTo(double x, double y) {
    _bounder.extendPoint(_matrix, x, y);
  }

  void _lineTo(double x, double y) {
    _bounder.extendPoint(_matrix, x, y);
  }

  void _curveTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    _bounder.extendPoint(_matrix, x1, y1);
    _bounder.extendPoint(_matrix, x2, y2);
    _bounder.extendPoint(_matrix, x3, y3);
  }

  void _closePath() {}

  PathWalker getWalker() {
    return PathWalker.implement(
        moveTo: _moveTo,
        lineTo: _lineTo,
        curveTo: _curveTo,
        closePath: _closePath);
  }
}

class TextBounder {
  final Bounder _bounder;
  final Matrix _matrix;

  TextBounder(this._bounder, this._matrix);

  void showGlyph(Font font, Matrix trm, int gid, int ucs, bool bidi) {
    Rect bbox = Rect.ctor1(0, -0.2, font.advanceGlyph(gid, false), 0.8);
    _bounder.extendRect(trm.concat(_matrix), bbox);
  }

  TextWalker getWalker() {
    return TextWalker.implement(showGlyph: showGlyph);
  }
}

class BBoxDevice {
  final Bounder _bounder = Bounder();

  ExtendedDevice getDevice() {
    return ExtendedDevice.ctor2(DeviceInterface.implement(
        close: () {},
        fillPath: fillPath,
        clipPath: clipPath,
        strokePath: strokePath,
        clipStrokePath: clipStrokePath,
        fillText: fillText,
        clipText: clipText,
        strokeText: strokeText,
        clipStrokeText: clipStrokeText,
        ignoreText: ignoreText,
        fillShade: fillShade,
        fillImage: fillImage,
        fillImageMask: fillImageMask,
        clipImageMask: (_, __) {},
        popClip: () {},
        beginMask: (_, __, ___, ____, _____) {},
        endMask: () {},
        beginGroup: (_, __, ___, ____, _____, ______) {},
        endGroup: () {},
        beginTile: (_, __, ___, ____, _____, ______) {
          return 0;
        },
        endTile: () {},
        renderFlags: (_, __) {},
        setDefaultColorSpaces: (_) {},
        beginLayer: (_) {},
        endLayer: () {},
        beginStructure: (_, __, ___) {},
        endStructure: () {},
        beginMetatext: (_, __) {},
        endMetatext: () {}));
  }

  void fillPath(Path path, bool z, Matrix matrix, ColorSpace colorSpace,
      JArray<jfloat> fs, double f, int i) {
    path.walk(PathBounder(_bounder, matrix).getWalker());
  }

  void clipPath(Path path, bool z, Matrix matrix) {
    path.walk(PathBounder(_bounder, matrix).getWalker());
  }

  void strokePath(Path path, StrokeState strokeState, Matrix matrix,
      ColorSpace colorSpace, JArray<jfloat> fs, double f, int i) {
    path.walk(PathBounder(_bounder, matrix).getWalker());
  }

  void clipStrokePath(Path path, StrokeState strokeState, Matrix matrix) {
    path.walk(PathBounder(_bounder, matrix).getWalker());
  }

  void fillText(Text text, Matrix matrix, ColorSpace colorSpace,
      JArray<jfloat> fs, double f, int i) {
    text.walk(TextBounder(_bounder, matrix).getWalker());
  }

  void clipText(Text text, Matrix matrix) {
    text.walk(TextBounder(_bounder, matrix).getWalker());
  }

  void strokeText(Text text, StrokeState strokeState, Matrix matrix,
      ColorSpace colorSpace, JArray<jfloat> fs, double f, int i) {
    text.walk(TextBounder(_bounder, matrix).getWalker());
  }

  void clipStrokeText(Text text, StrokeState strokeState, Matrix matrix) {
    text.walk(TextBounder(_bounder, matrix).getWalker());
  }

  void ignoreText(Text text, Matrix matrix) {
    text.walk(TextBounder(_bounder, matrix).getWalker());
  }

  void fillShade(Shade shade, Matrix matrix, double f, int i) {
    //Rect bbox = shade;
    Rect bbox = Rect.ctor1(0, 0, 0, 0);
    _bounder.extend(bbox.x0, bbox.y0);
    _bounder.extend(bbox.x1, bbox.y1);
  }

  void fillImage(Image image, Matrix matrix, double f, int i) {
    _bounder.extendRect(matrix, Rect.ctor1(0, 0, 1, 1));
  }

  void fillImageMask(Image image, Matrix matrix, ColorSpace colorSpace,
      JArray<jfloat> fs, double f, int i) {
    _bounder.extendRect(matrix, Rect.ctor1(0, 0, 1, 1));
  }

  Rect getBounds() {
    return _bounder.bbox;
  }
}
