import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:lazyext/android_file_storage.dart';

import '../pdf/storage.dart';
import 'packagE:image/image.dart' as img;

import 'package:flutter/material.dart';
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

class MergedView extends StatefulWidget {
  final List<Exercise> exercises;
  const MergedView({super.key, required this.exercises});

  @override
  State<MergedView> createState() => _MergedViewState();
}

class _MergedViewState extends State<MergedView>
    with AutomaticKeepAliveClientMixin<MergedView> {
  static Storage? storage;
  static Future<mupdf.PDFDocument>? document;
  static Future<Directory>? dir;

  @override
  void initState() {
    AndroidFileStorage().storage?.then((Storage? value) => storage = value);
    document = PracticeMerger().exercisesToPDFDocument(widget.exercises);
    dir = getTemporaryDirectory();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: document,
        builder:
            (BuildContext context, AsyncSnapshot<mupdf.PDFDocument> snapshot) {
          mupdf.PDFDocument? document = snapshot.data;
          if (document != null) {
            return FutureBuilder(
              future: dir,
              builder:
                  (BuildContext context, AsyncSnapshot<Directory> snapshot) {
                Directory? dir = snapshot.data;
                if (dir != null) {
                  File file = File("${dir.path}/current.pdf");
                  document.save(file.path.toJString(), file.path.toJString());
                  PdfController controller =
                      PdfController(document: PdfDocument.openFile(file.path));
                  return Column(children: [
                    TextButton(
                        onPressed: () {
                          storage?.savePDF([], document);
                        },
                        child: const Text("Save")),
                    Expanded(
                        child: PdfView(
                      controller: controller,
                    )),
                  ]);
                } else {
                  return const Placeholder();
                }
              },
            );
          } else {
            return const Placeholder();
          }
        });
  }

  @override
  bool get wantKeepAlive => true;
}

class ExerciseListView extends StatefulWidget {
  final List<Exercise> exercises;
  const ExerciseListView({super.key, required this.exercises});

  @override
  State<ExerciseListView> createState() => _ExerciseListViewState();
}

class _ExerciseListViewState extends State<ExerciseListView>
    with AutomaticKeepAliveClientMixin<ExerciseListView> {
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

  Future<List<ImageProvider>>? _imageProviders;
  @override
  void initState() {
    super.initState();
    _imageProviders = _exercisesToImageProviders(widget.exercises);
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
    super.build(context);
    return FutureBuilder(
      future: _imageProviders,
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

  @override
  bool get wantKeepAlive => true;
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
    Future<(String, List<Exercise>)> exercises =
        _extractor.getExerciseCollection(File(path));
    return TabBarView(children: [
      OriginalView(
        path: path,
      ),
      FutureBuilder(
        future: exercises,
        builder: (BuildContext context,
            AsyncSnapshot<(String, List<Exercise>)?> snapshot) {
          (String, List<Exercise>)? data = snapshot.data;
          if (data != null) {
            return ExercisesView(title: data.$1, exercises: data.$2);
          } else {
            return const Placeholder();
          }
        },
      ),
      FutureBuilder(
          future: exercises,
          builder: (BuildContext context,
              AsyncSnapshot<(String, List<Exercise>)?> snapshot) {
            (String, List<Exercise>)? data = snapshot.data;
            if (data != null) {
              return MergedView(exercises: data.$2);
            } else {
              return const Placeholder();
            }
          })
    ]);
  }
}
