import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../pdf/extractor.dart';

class OriginalView extends StatelessWidget {
  final String path;
  const OriginalView({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: PDFView(
          filePath: path,
          swipeHorizontal: true,
        ),
      ),
    ]);
  }
}

class ExercisesView extends StatelessWidget {
  final List<Exercise> exercises;
  const ExercisesView({super.key, required this.exercises});

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: ListView.separated(
      itemCount: exercises.length,
      itemBuilder: (BuildContext context, int index) {
        ImageProvider? image = exercises[index].image;
        if (image != null) {
          return Image(
            image: image,
          );
        }
        return const Text("No image.");
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
    return DefaultTabController(
      length: 2,
      child: TabBarView(children: [
        OriginalView(
          path: path,
        ),
        FutureBuilder(
          future: _extractor.getExerciseCollection(File(path)),
          builder: (BuildContext context,
              AsyncSnapshot<(String, List<Exercise>)> snapshot) {
            (String, List<Exercise>)? data = snapshot.data;
            if (data != null) {
              return ExercisesView(exercises: data.$2);
            } else {
              return const Placeholder();
            }
          },
        )
      ]),
    );
  }
}
