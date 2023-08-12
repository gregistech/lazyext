package com.gergovari.mupdf;

import com.artifex.mupdf.fitz.ColorSpace;
import com.artifex.mupdf.fitz.DefaultColorSpaces;
import com.artifex.mupdf.fitz.Image;
import com.artifex.mupdf.fitz.Matrix;
import com.artifex.mupdf.fitz.Path;
import com.artifex.mupdf.fitz.Rect;
import com.artifex.mupdf.fitz.Shade;
import com.artifex.mupdf.fitz.StrokeState;
import com.artifex.mupdf.fitz.Text;

@SuppressWarnings("unused")
public interface DeviceInterface {
    void close();
    void fillPath(Path path, boolean z, Matrix matrix, ColorSpace colorSpace, float[] fs, double f, int i);
    void clipPath(Path path, boolean z, Matrix matrix);
    void strokePath(Path path, StrokeState strokeState, Matrix matrix, ColorSpace colorSpace, float[] fs, double f, int i);
    void clipStrokePath(Path path, StrokeState strokeState, Matrix matrix);
    void fillText(Text text, Matrix matrix, ColorSpace colorSpace, float[] fs, double f, int i);
    void clipText(Text text, Matrix matrix);
    void strokeText(Text text, StrokeState strokeState, Matrix matrix, ColorSpace colorSpace, float[] fs, double f, int i);
    void clipStrokeText(Text text, StrokeState strokeState, Matrix matrix);
    void ignoreText(Text text, Matrix matrix);
    void fillShade(Shade shade, Matrix matrix, double f, int i);
    void fillImage(Image image, Matrix matrix, double f, int i);
    void fillImageMask(Image image, Matrix matrix, ColorSpace colorSpace, float[] fs, double f, int i);
    void clipImageMask(Image image, Matrix matrix);
    void popClip();
    void beginMask(Rect rect, boolean z, ColorSpace colorSpace, float[] fs, int i);
    void endMask();
    void beginGroup(Rect rect, ColorSpace colorSpace, boolean z, boolean z1, int i, float f);
    void endGroup();
    int beginTile(Rect rect, Rect rect1, float f, float f1, Matrix matrix, int i);
    void endTile();
    void renderFlags(int i, int i1);
    void setDefaultColorSpaces(DefaultColorSpaces defaultColorSpaces);
    void beginLayer(String s);
    void endLayer();
    void beginStructure(int i, String s, int i1);
    void endStructure();
    void beginMetatext(int i, String s);
    void endMetatext();
}
