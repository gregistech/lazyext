import 'package:flutter/material.dart';
import 'package:lazyext/widgets/course.dart';

import 'screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  @override
  Widget build(BuildContext context) {
    return const ScreenWidget(
      title: "Courses",
      child: CoursesListView(),
    );
  }
}
