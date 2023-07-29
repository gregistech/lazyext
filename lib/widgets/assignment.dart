import 'package:flutter/material.dart' hide Material;
import 'package:go_router/go_router.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:provider/provider.dart';

import '../google/classroom.dart';
import 'g_paginated_list_view.dart';

class Assignment implements Comparable<Assignment> {
  late final String id;
  late final String name;
  late final String text;
  late final List<Material> materials;
  late final DateTime creationTime;

  Assignment(this.id, this.name, this.text, this.materials, this.creationTime);
  Assignment.fromAnnouncement(Announcement announcement) {
    id = announcement.id ?? "";
    text = announcement.text ?? "";
    name = announcement.text?.substring(
            0,
            (announcement.text?.length ?? 0) > 21
                ? 20
                : (announcement.text?.length ?? 1) - 1) ??
        "";
    materials = announcement.materials ?? [];
    creationTime = DateTime.parse(announcement.creationTime ?? "");
  }
  Assignment.fromCourseWork(CourseWork courseWork) {
    id = courseWork.id ?? "";
    text = courseWork.description ?? "";
    name = courseWork.title ?? "";
    materials = courseWork.materials ?? [];
    creationTime = DateTime.parse(courseWork.creationTime ?? "");
  }

  @override
  int compareTo(Assignment other) {
    return creationTime.compareTo(other.creationTime);
  }
}

class AssignmentListItem extends StatelessWidget {
  final Assignment assignment;
  const AssignmentListItem({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Text(assignment.name),
      onPressed: () {
        context.push("/course/assignment", extra: assignment);
      },
    );
  }
}

class AssignmentView extends StatelessWidget {
  final Assignment assignment;
  const AssignmentView({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    List<Widget> materials = [];
    for (Material material in assignment.materials) {
      if (material.driveFile != null) {
        materials.add(TextButton(
          child: Text(material.driveFile?.driveFile?.title ?? "UNKNOWN"),
          onPressed: () {},
        ));
      }
    }
    return Column(
      children: [
        Text(assignment.name),
        Text(assignment.text),
        Column(
          children: materials,
        )
      ],
    );
  }
}

class AssignmentListView extends StatefulWidget {
  final String courseId;
  const AssignmentListView({super.key, required this.courseId});

  @override
  State<AssignmentListView> createState() => _AssignmentListViewState();
}

class _AssignmentListViewState extends State<AssignmentListView> {
  List<bool> reachedLast = [false, false];
  List<String> ids = [];

  @override
  Widget build(BuildContext context) {
    return GPaginatedListView<(String?, String?), Assignment>(
        getPage: (int pageSize, (String?, String?)? token) async {
          int sizeCourseWork = (pageSize / 2).ceil();
          Future<(List<Announcement>, String?)>? announcementJob =
              reachedLast[0]
                  ? null
                  : Provider.of<Classroom>(context, listen: false)
                      .getAnnouncements(widget.courseId,
                          pageSize: pageSize - sizeCourseWork,
                          token: token?.$1);
          Future<(List<CourseWork>, String?)>? courseWorkJob = reachedLast[1]
              ? null
              : Provider.of<Classroom>(context, listen: false).getCourseWork(
                  widget.courseId,
                  pageSize: sizeCourseWork,
                  token: token?.$2);

          (List<Announcement>, String?)? announcementResponse =
              await announcementJob;
          List<Announcement>? announcements = announcementResponse?.$1;
          announcements ??= [];
          String? announcementToken = announcementResponse?.$2;
          reachedLast[0] = announcementToken == null;

          (List<CourseWork>, String?)? courseWorkResponse = await courseWorkJob;
          List<CourseWork>? courseWork = courseWorkResponse?.$1;
          courseWork ??= [];
          String? courseWorkToken = courseWorkResponse?.$2;
          reachedLast[1] = courseWorkToken == null;

          List<Assignment> assignments = announcements
                  .map((Announcement announcement) =>
                      Assignment.fromAnnouncement(announcement))
                  .toList() +
              courseWork
                  .map((CourseWork courseWork) =>
                      Assignment.fromCourseWork(courseWork))
                  .toList();

          return (
            assignments,
            announcementToken == null && courseWorkToken == null
                ? null
                : (announcementToken, courseWorkToken)
          );
        },
        comparator: (a, b) => b.compareTo(a),
        shouldSort: true,
        itemBuilder: (BuildContext context, Assignment item, int index) =>
            AssignmentListItem(assignment: item));
  }
}
