import 'dart:io';

import 'package:async/async.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:jni/jni.dart';
import 'package:lazyext/pdf/extractor.dart';
import 'package:lazyext/pdf/merger.dart';
import 'package:lazyext/screens/screen.dart';
import 'package:lazyext/widgets/compare.dart';
import 'package:mupdf_android/mupdf_android.dart' hide Text;
import 'package:uuid/uuid.dart';

class CompareScreen extends StatelessWidget {
  final Iterable<String> path;
  const CompareScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    const List<Tab> tabs = [
      Tab(icon: Text("Original")),
      Tab(icon: Text("Merged"))
    ];
    return DefaultTabController(
        length: tabs.length, child: CompareScreenView(tabs: tabs, paths: path));
  }
}

class CompareScreenView extends StatefulWidget {
  const CompareScreenView({
    super.key,
    required this.tabs,
    required this.paths,
  });

  final List<Tab> tabs;
  final Iterable<String> paths;

  @override
  State<CompareScreenView> createState() => _CompareScreenViewState();
}

class _CompareScreenViewState extends State<CompareScreenView> {
  int index = 0;

  late Stream<Exercise> exercises = _getExerciseStream();

  Future<void> _mergeAndSave(Merger merger) async {
    setState(() => loading = true);
    Future<PDFDocument> document = merger.exercisesToPDFDocument(exercises);
    String? dir = await FilePicker.platform.getDirectoryPath();
    if (dir != null) {
      String path = "$dir/${const Uuid().v4()}.pdf";
      (await document).save(path.toJString(), path.toJString());
    }
    setState(() => loading = false);
  }

  Stream<Exercise> _getExerciseStream() =>
      StreamGroup.mergeBroadcast(widget.paths
          .map((e) => ExerciseExtractor().getExercisesFromFile(File(e)))
          .toList());

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    DefaultTabController.of(context).addListener(
        () => setState(() => index = DefaultTabController.of(context).index));
    return ScreenWidget(
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: index == 1
          ? ExpandableFab(
              openButtonBuilder: DefaultFloatingActionButtonBuilder(
                  child: const Icon(Icons.merge)),
              closeButtonBuilder: DefaultFloatingActionButtonBuilder(
                  child: const Icon(Icons.close_rounded)),
              children: [
                FloatingActionButton(
                    onPressed: () {
                      _mergeAndSave(PracticeMerger());
                    },
                    child: const Icon(Icons.edit_rounded)),
                FloatingActionButton(
                    onPressed: () {
                      _mergeAndSave(SummaryMerger());
                    },
                    child: const Icon(Icons.summarize_rounded))
              ],
            )
          : null,
      title: "Compare",
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Column(
          children: [
            TabBar(
              tabs: widget.tabs,
            ),
            Visibility(
                visible: loading, child: const LinearProgressIndicator()),
          ],
        ),
      ),
      child: CompareView(paths: widget.paths, exercises: exercises),
    );
  }
}
