package com.gergovari.mupdf;

import com.artifex.mupdf.fitz.ColorSpace;
import com.artifex.mupdf.fitz.DefaultColorSpaces;
import com.artifex.mupdf.fitz.Device;
import com.artifex.mupdf.fitz.Image;
import com.artifex.mupdf.fitz.Matrix;
import com.artifex.mupdf.fitz.Path;
import com.artifex.mupdf.fitz.Rect;
import com.artifex.mupdf.fitz.Shade;
import com.artifex.mupdf.fitz.StrokeState;
import com.artifex.mupdf.fitz.Text;

public class ExtendedDevice extends Device {
    DeviceInterface deviceInterface;
    public ExtendedDevice(DeviceInterface deviceInterface) {
        this.deviceInterface = deviceInterface;
    }

    @Override
    public void close() {
        deviceInterface.close();
    }

    @Override
    public void fillPath(Path path, boolean b, Matrix matrix, ColorSpace colorSpace, float[] floats, float v, int i) {
        deviceInterface.fillPath(path, b, matrix, colorSpace, floats, v, i);
    }

    @Override
    public void strokePath(Path path, StrokeState strokeState, Matrix matrix, ColorSpace colorSpace, float[] floats, float v, int i) {
        deviceInterface.strokePath(path, strokeState, matrix, colorSpace, floats, v, i);
    }

    @Override
    public void clipPath(Path path, boolean b, Matrix matrix) {
        deviceInterface.clipPath(path, b, matrix);
    }

    @Override
    public void clipStrokePath(Path path, StrokeState strokeState, Matrix matrix) {
        deviceInterface.clipStrokePath(path, strokeState, matrix);
    }

    @Override
    public void fillText(Text text, Matrix matrix, ColorSpace colorSpace, float[] floats, float v, int i) {
        deviceInterface.fillText(text, matrix, colorSpace, floats, v, i);
    }

    @Override
    public void strokeText(Text text, StrokeState strokeState, Matrix matrix, ColorSpace colorSpace, float[] floats, float v, int i) {
        deviceInterface.strokeText(text, strokeState, matrix, colorSpace, floats, v, i);
    }

    @Override
    public void clipText(Text text, Matrix matrix) {
        deviceInterface.clipText(text, matrix);
    }

    @Override
    public void clipStrokeText(Text text, StrokeState strokeState, Matrix matrix) {
        deviceInterface.clipStrokeText(text, strokeState, matrix);
    }

    @Override
    public void ignoreText(Text text, Matrix matrix) {
        deviceInterface.ignoreText(text, matrix);
    }

    @Override
    public void fillShade(Shade shade, Matrix matrix, float v, int i) {
        deviceInterface.fillShade(shade, matrix, v, i);
    }

    @Override
    public void fillImage(Image image, Matrix matrix, float v, int i) {
        deviceInterface.fillImage(image, matrix, v, i);
    }

    @Override
    public void fillImageMask(Image image, Matrix matrix, ColorSpace colorSpace, float[] floats, float v, int i) {
        deviceInterface.fillImageMask(image, matrix, colorSpace, floats, v, i);
    }

    @Override
    public void clipImageMask(Image image, Matrix matrix) {
        deviceInterface.clipImageMask(image, matrix);
    }

    @Override
    public void popClip() {
        deviceInterface.popClip();
    }

    @Override
    public void beginMask(Rect rect, boolean b, ColorSpace colorSpace, float[] floats, int i) {
        deviceInterface.beginMask(rect, b, colorSpace, floats, i);
    }

    @Override
    public void endMask() {
        deviceInterface.endMask();
    }

    @Override
    public void beginGroup(Rect rect, ColorSpace colorSpace, boolean b, boolean b1, int i, float v) {
        deviceInterface.beginGroup(rect, colorSpace, b, b1, i, v);
    }

    @Override
    public void endGroup() {
        deviceInterface.endGroup();
    }

    @Override
    public int beginTile(Rect rect, Rect rect1, float v, float v1, Matrix matrix, int i) {
        return deviceInterface.beginTile(rect, rect1, v, v1, matrix, i);
    }

    @Override
    public void endTile() {
        deviceInterface.endTile();
    }

    @Override
    public void renderFlags(int i, int i1) {
        deviceInterface.renderFlags(i, i1);
    }

    @Override
    public void setDefaultColorSpaces(DefaultColorSpaces defaultColorSpaces) {
        deviceInterface.setDefaultColorSpaces(defaultColorSpaces);
    }

    @Override
    public void beginLayer(String s) {
        deviceInterface.beginLayer(s);
    }

    @Override
    public void endLayer() {
        deviceInterface.endLayer();
    }

    @Override
    public void beginStructure(int i, String s, int i1) {
        deviceInterface.beginStructure(i, s, i1);
    }

    @Override
    public void endStructure() {
        deviceInterface.endStructure();
    }

    @Override
    public void beginMetatext(int i, String s) {
        deviceInterface.beginMetatext(i, s);
    }

    @Override
    public void endMetatext() {
        deviceInterface.endMetatext();
    }

}
