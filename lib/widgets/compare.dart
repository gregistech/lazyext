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
  const ExerciseListView({super.key, required this.stream});

  @override
  State<ExerciseListView> createState() => _ExerciseListViewState();
}

class _ExerciseListViewState extends State<ExerciseListView>
    with AutomaticKeepAliveClientMixin<ExerciseListView> {
  Stream<ImageProvider> _exercisesToImageProviders(
      Stream<Exercise> exercises) async* {
    await for (Exercise exercise in exercises) {
      img.Image? image = exercise.image;
      if (image != null) {
        ImageProvider? provider = await _imageToImageProvider(image);
        if (provider != null) {
          yield provider;
        }
      }
    }
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

  int imageCount = 0;

  final List<ImageProvider> _imageProviders = [];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder(
      stream: _exercisesToImageProviders(widget.stream),
      builder: (BuildContext context,
          AsyncSnapshot<ImageProvider<Object>> snapshot) {
        ImageProvider? provider = snapshot.data;
        if (provider != null) {
          _imageProviders.add(provider);
        }
        return ListView.separated(
          itemBuilder: (context, index) {
            try {
              return Image(image: _imageProviders[index]);
            } on RangeError {
              return const Placeholder();
            }
          },
          separatorBuilder: (BuildContext context, int index) => const Divider(
            height: 1,
          ),
          itemCount: _imageProviders.length,
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class MergeView extends StatefulWidget {
  final Stream<Exercise> stream;
  const MergeView({super.key, required this.stream});

  @override
  State<MergeView> createState() => _MergeViewState();
}

class _MergeViewState extends State<MergeView> {
  @override
  Widget build(BuildContext context) {
    return ExerciseListView(stream: widget.stream);
  }
}

class CompareView extends StatelessWidget {
  final Iterable<String> paths;
  final Stream<Exercise> exercises;
  const CompareView({super.key, required this.paths, required this.exercises});

  @override
  Widget build(BuildContext context) {
    return TabBarView(children: [
      OriginalView(
        paths: paths,
      ),
      MergeView(stream: exercises),
    ]);
  }
}
