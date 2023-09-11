import 'dart:core';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'packagE:image/image.dart' as img;

import 'package:flutter/material.dart';
import 'package:jni/jni.dart';
import 'package:mupdf_android/mupdf_android.dart' as mupdf;
import 'package:pdfx/pdfx.dart';

import '../pdf/extractor.dart';

class OriginalView extends StatefulWidget {
  final Iterable<String> paths;
  final void Function(List<String>) onPathsChange;
  const OriginalView(
      {super.key, required this.paths, required this.onPathsChange});

  @override
  State<OriginalView> createState() => _OriginalViewState();
}

class _OriginalViewState extends State<OriginalView>
    with AutomaticKeepAliveClientMixin {
  late final Map<String, (Widget, Widget)> paths =
      Map.fromEntries(widget.paths.map((e) => MapEntry(e, (
            Tab(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Visibility(
                  visible: widget.paths.length > 1,
                  child: IconButton(
                    icon: const Icon(Icons.close_outlined),
                    onPressed: () {
                      setState(() {
                        paths.remove(e);
                        widget.onPathsChange(paths.keys.toList());
                      });
                    },
                  ),
                ),
                Text(mupdf.Document.openDocument(e.toJString()).title),
              ],
            )),
            PdfView(
                controller: PdfController(document: PdfDocument.openFile(e)))
          ))));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
        length: paths.length,
        child: Column(
          children: [
            TabBar.secondary(
                isScrollable: true,
                tabs: paths.values.map((e) => e.$1).toList()),
            Expanded(
              child:
                  TabBarView(children: paths.values.map((e) => e.$2).toList()),
            ),
          ],
        ));
  }

  @override
  bool get wantKeepAlive => true;
}

class ExerciseListView extends StatefulWidget {
  final List<Exercise> exercises;
  const ExerciseListView(
      {super.key, required this.exercises, this.exercisesChanged});
  final void Function(List<Exercise>)? exercisesChanged;

  @override
  State<ExerciseListView> createState() => _ExerciseListViewState();
}

class _ExerciseListViewState extends State<ExerciseListView>
    with AutomaticKeepAliveClientMixin {
  List<Future<ImageProvider?>> _exercisesToImageProviders(
      List<Exercise> exercises) {
    List<Future<ImageProvider?>> providers = [];
    for (Exercise exercise in exercises) {
      img.Image? image = exercise.image;
      if (image != null) {
        providers.add(_imageToImageProvider(image));
      }
    }
    return providers;
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

  late final List<Exercise> exercises = widget.exercises;
  late final List<Future<ImageProvider?>> providers =
      _exercisesToImageProviders(widget.exercises);
  Map<int, bool> disabled = {};

  List<Exercise> get enabledExercises {
    List<Exercise> result = [];
    for (int i = 0; i < exercises.length; i++) {
      if (disabled[i] ?? false) {
        continue;
      } else {
        result.add(exercises[i]);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ReorderableListView.builder(
      itemBuilder: (context, index) {
        return ExerciseListItem(
          key: Key(index.toString()),
          provider: providers[index],
          onChanged: (bool change) {
            setState(() {
              disabled[index] = !change;
            });
          },
          value: !(disabled[index] ?? false),
        );
      },
      itemCount: providers.length,
      onReorder: (int aI, int bI) {
        setState(() {
          Exercise b = exercises[bI];
          bool? bDisabled = disabled[bI];
          Future<ImageProvider?> bProvider = providers[bI];
          Exercise a = exercises[aI];
          bool? aDisabled = disabled[aI];
          Future<ImageProvider?> aProvider = providers[aI];
          exercises[bI] = a;
          disabled[bI] = aDisabled ?? false;
          providers[bI] = aProvider;
          exercises[aI] = b;
          disabled[aI] = bDisabled ?? false;
          providers[aI] = bProvider;
          final exercisesChanged = widget.exercisesChanged;
          if (exercisesChanged != null) {
            exercisesChanged(enabledExercises);
          }
        });
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class ExerciseListItem extends StatefulWidget {
  const ExerciseListItem(
      {super.key,
      required this.provider,
      required this.onChanged,
      required this.value});

  final Future<ImageProvider?> provider;
  final void Function(bool change) onChanged;
  final bool value;

  @override
  State<ExerciseListItem> createState() => _ExerciseListItemState();
}

class _ExerciseListItemState extends State<ExerciseListItem> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider?>(
        future: widget.provider,
        builder: (context, snapshot) {
          Widget tile(Widget child) => Row(
                children: [
                  Expanded(
                    child: Stack(alignment: Alignment.centerLeft, children: [
                      child,
                      Checkbox(
                        value: widget.value,
                        onChanged: (bool? change) {
                          widget.onChanged(change ?? false);
                        },
                      ),
                    ]),
                  ),
                  const Icon(Icons.drag_handle_rounded, size: 45),
                ],
              );
          ImageProvider? provider = snapshot.data;
          if (provider == null) {
            return tile(const Center(child: CircularProgressIndicator()));
          } else {
            return tile(Image(image: provider));
          }
        });
  }
}
