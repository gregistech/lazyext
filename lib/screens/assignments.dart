import 'package:flutter/material.dart';
import 'package:lazyext/screens/screen.dart';

import '../widgets/assignment.dart';

class AssignmentScreen extends StatelessWidget {
  final Assignment assignment;
  const AssignmentScreen({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return ScreenWidget(
        title: "Assignment", child: AssignmentView(assignment: assignment));
  }
}

class AssignmentsScreen extends StatefulWidget {
  final String courseId;
  const AssignmentsScreen({super.key, required this.courseId});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  @override
  Widget build(BuildContext context) {
    return ScreenWidget(
      title: "Assignments",
      child: AssignmentListView(
        courseId: widget.courseId,
      ),
    );
  }
}
