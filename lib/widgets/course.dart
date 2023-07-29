import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:lazyext/widgets/g_paginated_list_view.dart';
import 'package:provider/provider.dart';

import '../google/classroom.dart';

class CourseListItem extends StatelessWidget {
  final Course course;
  const CourseListItem({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Text(course.name ?? "UNKNOWN"),
      onPressed: () => context.go("/course/${course.id}/assignment"),
    );
  }
}

class CoursesListView extends StatelessWidget {
  const CoursesListView({super.key});

  @override
  Widget build(BuildContext context) {
    return GPaginatedListView<String?, Course>(
        getPage: (pageSize, token) =>
            Provider.of<Classroom>(context, listen: false)
                .getCourses(token: token),
        itemBuilder: (BuildContext context, Course item, int index) =>
            CourseListItem(course: item));
  }
}
