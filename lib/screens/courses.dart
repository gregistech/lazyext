import 'package:flutter/material.dart';
import 'package:lazyext/widgets/course.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
      ),
      body: const Flex(
        direction: Axis.vertical,
        children: [
          Expanded(
            child: CoursesListView(),
          )
        ],
      ),
    );
  }
}
