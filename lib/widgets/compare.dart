import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'packagE:image/image.dart' as img;

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../pdf/extractor.dart';

class OriginalView extends StatelessWidget {
  final String path;
  late final PdfController _controller =
      PdfController(document: PdfDocument.openFile(path));
  OriginalView({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
          child: PdfView(
        controller: _controller,
      )),
    ]);
  }
}

class ExercisesView extends StatelessWidget {
  final List<Exercise> exercises;
  const ExercisesView({super.key, required this.exercises});

  Future<ImageProvider?> _imageToImageProvider(img.Image image) async {
    if (image.format != img.Format.uint8 || image.numChannels != 4) {
      final cmd = img.Command()
        ..image(image)
        ..convert(format: img.Format.uint8, numChannels: 4);
      final rgba8 = await cmd.getImageThread();
      if (rgba8 != null) {
        image = rgba8;
      }
    }

    ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromUint8List(image.toUint8List());

    ui.ImageDescriptor id = ui.ImageDescriptor.raw(buffer,
        height: image.height,
        width: image.width,
        pixelFormat: ui.PixelFormat.rgba8888);

    ui.Codec codec = await id.instantiateCodec(
        targetHeight: image.height, targetWidth: image.width);

    ui.FrameInfo fi = await codec.getNextFrame();
    ui.Image uiImage = fi.image;

    ByteData? byteData =
        await uiImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      return MemoryImage(byteData.buffer.asUint8List());
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: ListView.separated(
      itemCount: exercises.length,
      itemBuilder: (BuildContext context, int index) {
        img.Image? image = exercises[index].image;
        if (image != null) {
          return FutureBuilder<ImageProvider?>(
              future: _imageToImageProvider(image),
              builder: (BuildContext context,
                  AsyncSnapshot<ImageProvider?> snapshot) {
                ImageProvider? image = snapshot.data;
                if (image != null) {
                  return Image(image: image);
                } else {
                  return const Placeholder();
                }
              });
        } else {
          return const Placeholder();
        }
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Divider(
          height: 1,
        );
      },
    ));
  }
}

class CompareView extends StatelessWidget {
  final String path;
  final ExerciseExtractor _extractor = ExerciseExtractor();
  CompareView({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return TabBarView(children: [
      OriginalView(
        path: path,
      ),
      FutureBuilder(
        future: _extractor.getExerciseCollection(File(path)),
        builder: (BuildContext context,
            AsyncSnapshot<(String, List<Exercise>)?> snapshot) {
          (String, List<Exercise>)? data = snapshot.data;
          if (data != null) {
            return ColoredBox(
                color: const Color.fromARGB(1, 0, 0, 0),
                child: ExercisesView(exercises: data.$2));
          } else {
            return const Placeholder();
          }
        },
      )
    ]);
  }
}
