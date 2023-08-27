import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:lazyext/google/cached_teacher.dart';
import 'package:lazyext/widgets/cached_teacher_pfp.dart';
import 'package:lazyext/widgets/g_paginated_list_view.dart';
import 'package:provider/provider.dart';

import '../google/classroom.dart';

class CourseListItem extends StatelessWidget {
  final Course course;
  const CourseListItem({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CachedTeacher?>(
        future: Provider.of<CachedTeacherProvider>(context, listen: false)
            .getTeacher(course.id ?? "", course.ownerId ?? ""),
        builder:
            (BuildContext context, AsyncSnapshot<CachedTeacher?> snapshot) {
          CachedTeacher? teacher = snapshot.data;
          return ListTile(
            onTap: () => context.push("/courses/assignments", extra: course),
            leading: CachedTeacherProfilePicture(teacher: teacher),
            title: Text(course.name ?? "UNKNOWN"),
            subtitle: Text(teacher?.name ?? ""),
          );
        });
  }
}

class CoursesListView extends StatelessWidget {
  const CoursesListView({super.key});

  @override
  Widget build(BuildContext context) {
    return GPaginatedListView<String?, Course>(
        getPage: (pageSize, token) async =>
            (await Provider.of<Classroom>(context, listen: false)
                    .getCourses(token: token) ??
                (<Course>[], null)),
        itemBuilder: (BuildContext context, Course item, int index) =>
            CourseListItem(course: item));
  }
}
