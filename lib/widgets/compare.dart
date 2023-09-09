import 'dart:core';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'packagE:image/image.dart' as img;

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../pdf/extractor.dart';

class OriginalView extends StatelessWidget {
  final Iterable<String> paths;
  const OriginalView({super.key, required this.paths});

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: paths.length != 1,
      replacement: PdfView(
        controller: PdfController(document: PdfDocument.openFile(paths.first)),
      ),
      child: DefaultTabController(
          length: paths.length,
          child: Column(
            children: [
              TabBar.secondary(tabs: paths.map((e) => Tab(text: e)).toList()),
              Expanded(
                child: TabBarView(
                  children: paths
                      .map((e) => PdfView(
                          controller:
                              PdfController(document: PdfDocument.openFile(e))))
                      .toList(),
                ),
              ),
            ],
          )),
    );
  }
}

class ExerciseListView extends StatefulWidget {
  final Stream<Exercise> stream;
  const ExerciseListView({super.key, required this.stream, this.exerciseAdded});
  final void Function(Exercise)? exerciseAdded;

  @override
  State<ExerciseListView> createState() => _ExerciseListViewState();
}

class _ExerciseListViewState extends State<ExerciseListView> {
  Future<ImageProvider?> _exerciseToImageProvider(Exercise exercise) async {
    img.Image? image = exercise.image;
    if (image != null) {
      return _imageToImageProvider(image);
    }
    return null;
  }

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

  final List<Future<ImageProvider?>> providers = [];
  bool done = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Exercise>(
        stream: widget.stream,
        builder: (context, snapshot) {
          Exercise? data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (!done) {
              providers.add(_exerciseToImageProvider(data));
              final exerciseAdded = widget.exerciseAdded;
              if (exerciseAdded != null) {
                exerciseAdded(data);
              }
            }
            if (snapshot.connectionState == ConnectionState.done) {
              done = true;
            }
            return ListView.separated(
              itemBuilder: (context, index) {
                return FutureBuilder<ImageProvider?>(
                    future: providers[index],
                    builder: (context, snapshot) {
                      ImageProvider? provider = snapshot.data;
                      if (provider == null) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return Image(image: provider);
                    });
              },
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(
                height: 1,
              ),
              itemCount: providers.length,
            );
          }
        });
  }
}
