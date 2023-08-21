import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'packagE:image/image.dart' as img;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jni/jni.dart';
import 'package:lazyext/pdf/merger.dart';
import 'package:mupdf_android/mupdf_android.dart' as mupdf;
import 'package:path_provider/path_provider.dart';
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

class ExerciseListView extends StatefulWidget {
  final List<Exercise> exercises;
  const ExerciseListView({super.key, required this.exercises});

  @override
  State<ExerciseListView> createState() => _ExerciseListViewState();
}

class _ExerciseListViewState extends State<ExerciseListView> {
  Future<List<ImageProvider>> _exercisesToImageProviders(
      List<Exercise> exercises) async {
    List<ImageProvider> images = [];
    for (Exercise exercise in exercises) {
      img.Image? image = exercise.image;
      if (image != null) {
        ImageProvider? provider = await _imageToImageProvider(image);
        if (provider != null) {
          images.add(provider);
        }
      }
    }
    return images;
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _exercisesToImageProviders(widget.exercises),
      builder:
          (BuildContext context, AsyncSnapshot<List<ImageProvider>> snapshot) {
        List<ImageProvider>? images = snapshot.data;
        return ListView.separated(
          itemCount: widget.exercises.length,
          itemBuilder: (BuildContext context, int index) {
            if (images != null) {
              return Image(image: images[index]);
            } else {
              return const Placeholder();
            }
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider(
              height: 1,
            );
          },
        );
      },
    );
  }
}

class ExercisesView extends StatefulWidget {
  final String title;
  final List<Exercise> exercises;
  const ExercisesView(
      {super.key, required this.title, required this.exercises});

  @override
  State<ExercisesView> createState() => _ExercisesViewState();
}

class _ExercisesViewState extends State<ExercisesView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.title),
        TextButton(
          onPressed: () async {
            Merger merger = PracticeMerger();
            mupdf.PDFDocument pdf =
                await merger.exercisesToPDFDocument(widget.exercises);
            String path = "${(await getTemporaryDirectory()).path}/merged.pdf";
            File file = File.fromUri(Uri.file(path));
            pdf.save(file.path.toJString(), file.path.toJString());
            // ignore: use_build_context_synchronously
            if (!context.mounted) return;
            context.go("/compare", extra: file.path);
          },
          child: const Text("Merge"),
        ),
        Flexible(child: ExerciseListView(exercises: widget.exercises)),
      ],
    );
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
            return ExercisesView(title: data.$1, exercises: data.$2);
          } else {
            return const Placeholder();
          }
        },
      )
    ]);
  }
}
