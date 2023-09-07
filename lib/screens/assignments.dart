import 'package:flutter/material.dart' hide Material;
import 'package:googleapis/classroom/v1.dart' hide Assignment;
import 'package:lazyext/screens/screen.dart';

import '../widgets/assignment.dart';

class AssignmentsScreen extends StatefulWidget {
  final Course course;
  const AssignmentsScreen({super.key, required this.course});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  List<Material> selected = [];

  @override
  Widget build(BuildContext context) {
    return ScreenWidget(
      title: "Assignments",
      floatingActionButton: Visibility(
          visible: selected.isNotEmpty,
          child: FloatingActionButton.extended(
            label: const Text("Open"),
            icon: const Icon(Icons.file_open),
            onPressed: () {},
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      child: AssignmentListView(
        course: widget.course,
        onSelectionChanged: (selection) => setState(() => selected = selection),
      ),
    );
  }
}
