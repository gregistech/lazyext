import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:go_router/go_router.dart';
import 'package:jni/jni.dart';
import 'package:lazyext/pdf/mapper.dart';
import 'package:lazyext/pdf/extractor.dart';
import 'package:lazyext/screens/screen.dart';
import 'package:lazyext/widgets/compare.dart';
import 'package:mupdf_android/mupdf_android.dart' hide Text;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class CompareScreen extends StatelessWidget {
  final Iterable<PDFDocument> documents;
  const CompareScreen({super.key, required this.documents});

  @override
  Widget build(BuildContext context) {
    const List<Tab> tabs = [
      Tab(icon: Text("Original")),
      Tab(icon: Text("Merged"))
    ];
    return DefaultTabController(
        length: tabs.length,
        child: CompareScreenView(
          tabs: tabs,
          documents: documents,
        ));
  }
}

class CompareScreenView extends StatefulWidget {
  const CompareScreenView({
    super.key,
    required this.tabs,
    required this.documents,
  });

  final List<Tab> tabs;
  final Iterable<PDFDocument> documents;

  @override
  State<CompareScreenView> createState() => _CompareScreenViewState();
}

class _CompareScreenViewState extends State<CompareScreenView>
    with AutomaticKeepAliveClientMixin {
  int index = 0;

  Future<void> _mergeAndSave(Extractor merger, List<Exercise> exercises) async {
    setState(() => loading = true);
    Future<PDFDocument?> document = merger.exercisesToDocument(exercises);
    if (!context.mounted) return;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Successful merge"),
            content: const Text("Exercises have been successfully merged."),
            actions: [
              ElevatedButton(
                  onPressed: () async {
                    String? dir = await FilePicker.platform.getDirectoryPath();
                    if (dir != null) {
                      String path = "$dir/${const Uuid().v4()}.pdf";
                      (await document)?.save(
                          path.toJString(),
                          "compress,compress-images,garbage=compact"
                              .toJString());
                      if (context.mounted) {
                        context.pop();
                      }
                    }
                  },
                  child: const Text("Save")),
              ElevatedButton(
                  onPressed: () async {
                    String dir = (await getTemporaryDirectory()).path;
                    String path = "$dir/${const Uuid().v4()}.pdf";
                    (await document)?.save(path.toJString(),
                        "compress,compress-images,garbage=compact".toJString());
                    await Share.shareXFiles([XFile(path)]);
                    if (context.mounted) {
                      context.pop();
                    }
                  },
                  child: const Text("Share")),
            ],
          );
        });
    setState(() => loading = false);
  }

  final ExerciseMapper _mapper = ExerciseMapper();

  late Future<List<List<Exercise>>> result = (documents
      .fold<List<Future<List<Exercise>>>>([], (previousValue, document) {
    return previousValue + [_mapper.documentToExercises(document)];
  })).wait;

  late List<PDFDocument> documents = widget.documents.toList();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    DefaultTabController.of(context).addListener(
        () => setState(() => index = DefaultTabController.of(context).index));
    return ScreenWidget(
        floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
        floatingActionButtonLocation: ExpandableFab.location,
        floatingActionButton: index == 1
            ? FutureBuilder<List<List<Exercise>>>(
                future: result,
                builder: (context, snapshot) {
                  List<List<Exercise>>? data = snapshot.data;
                  if (data != null) {
                    List<Exercise> exercises = data.fold([],
                        (previousValue, element) => previousValue + element);
                    return ExpandableFab(
                      openButtonBuilder: RotateFloatingActionButtonBuilder(
                          child: const Icon(Icons.merge_rounded)),
                      closeButtonBuilder: RotateFloatingActionButtonBuilder(
                          child: const Icon(Icons.close_rounded)),
                      children: [
                        FloatingActionButton(
                            heroTag: "practice",
                            onPressed: () {
                              _mergeAndSave(
                                  PracticeExtractor(exercises
                                      .first.document.pages.first
                                      .getBounds1()),
                                  exercises);
                            },
                            child: const Icon(Icons.psychology_rounded)),
                        FloatingActionButton(
                            heroTag: "summary",
                            onPressed: () {
                              _mergeAndSave(
                                  SummaryExtractor(exercises
                                      .first.document.pages.first
                                      .getBounds1()),
                                  exercises);
                            },
                            child: const Icon(Icons.summarize_rounded))
                      ],
                    );
                  } else {
                    return const FloatingActionButton(
                        onPressed: null, child: CircularProgressIndicator());
                  }
                })
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
        child: TabBarView(children: [
          OriginalView(
            documents: documents,
            onDocumentsChange: (p0) => documents = p0,
          ),
          FutureBuilder<List<List<Exercise>>>(
              future: result,
              builder: (context, snapshot) {
                List<List<Exercise>>? data = snapshot.data;
                if (data != null) {
                  List<Exercise> exercises = data.fold(
                      [], (previousValue, element) => previousValue + element);
                  return ExerciseListView(
                    exercises: exercises,
                    exercisesChanged: (e) => setState(() {
                      result = Future.value([e]);
                    }),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              })
        ]));
  }

  @override
  bool get wantKeepAlive => true;
}
