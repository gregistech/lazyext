import 'package:flutter/material.dart';
import 'package:googleapis/classroom/v1.dart' hide Assignment;
import 'package:lazyext/screens/screen.dart';

import '../widgets/assignment.dart';

class AssignmentScreen extends StatelessWidget {
  final Course course;
  final Assignment assignment;
  const AssignmentScreen(
      {super.key, required this.course, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return ScreenWidget(
        title: "Assignment",
        child: AssignmentView(course: course, assignment: assignment));
  }
}

class AssignmentsScreen extends StatefulWidget {
  final Course course;
  const AssignmentsScreen({super.key, required this.course});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  @override
  Widget build(BuildContext context) {
    return ScreenWidget(
      title: "Assignments",
      child: AssignmentListView(course: widget.course),
    );
  }
}
