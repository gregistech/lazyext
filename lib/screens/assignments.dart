import 'package:flutter/material.dart';

import '../widgets/assignment.dart';

class AssignmentsScreen extends StatefulWidget {
  final String courseId;
  const AssignmentsScreen({super.key, required this.courseId});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
      ),
      body: Flex(
        direction: Axis.vertical,
        children: [
          Expanded(
            child: AssignmentListView(
              courseId: widget.courseId,
            ),
          )
        ],
      ),
    );
  }
}
