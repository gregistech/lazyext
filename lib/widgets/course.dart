import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
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
    return FutureBuilder<Teacher?>(
        future: Provider.of<Classroom>(context, listen: false)
            .getTeacher(course.id ?? "", course.ownerId ?? ""),
        builder: (BuildContext context, AsyncSnapshot<Teacher?> snapshot) {
          Teacher? teacher = snapshot.data;
          return ListTile(
            onTap: () => context.push("/courses/assignments", extra: course),
            leading: ProfilePicture(
              name: teacher?.profile?.name?.fullName ?? "Anonymous",
              img: teacher?.profile?.photoUrl == null
                  ? null
                  : "https:${teacher?.profile?.photoUrl}",
              radius: 21,
              fontsize: 17,
            ),
            title: Text(course.name ?? "UNKNOWN"),
            subtitle: Text(teacher?.profile?.name?.fullName ?? ""),
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
