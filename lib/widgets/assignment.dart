import 'package:flutter/material.dart' hide Material;
import 'package:go_router/go_router.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:googleapis/drive/v3.dart' hide Drive;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import '../google/classroom.dart';
import '../google/drive.dart';
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
  final Course course;
  final Assignment assignment;
  const AssignmentListItem(
      {super.key, required this.course, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Text(assignment.name),
      onPressed: () {
        context.push("/course/assignment", extra: (course, assignment));
      },
    );
  }
}

class AssignmentView extends StatelessWidget {
  final Course course;
  final Assignment assignment;
  const AssignmentView(
      {super.key, required this.course, required this.assignment});

  @override
  Widget build(BuildContext context) {
    List<Widget> materials = [];
    for (Material material in assignment.materials) {
      DriveFile? driveFile = material.driveFile?.driveFile;
      if (driveFile != null) {
        materials.add(FutureBuilder(
          future: Provider.of<Drive>(context, listen: false)
              .driveFileToFile(driveFile),
          builder: (BuildContext context, AsyncSnapshot<File?> snapshot) =>
              TextButton(
            child: Text(snapshot.data?.name ?? "UNKNOWN"),
            onPressed: () async {
              File? file = snapshot.data;
              if (file != null) {
                File? gdoc = await Provider.of<Drive>(context, listen: false)
                    .fileToGoogleDoc(file);
                if (gdoc != null) {
                  // ignore: use_build_context_synchronously
                  if (!context.mounted) return;
                  Media? pdf = await Provider.of<Drive>(context, listen: false)
                      .fileToPdf(gdoc);
                  if (pdf != null) {
                    // ignore: use_build_context_synchronously
                    if (!context.mounted) return;
                    String? path = await Provider.of<Drive>(context,
                            listen: false)
                        .downloadMedia(pdf,
                            "${(await getApplicationDocumentsDirectory()).path}/test.pdf");
                    if (path != null) {
                      // ignore: use_build_context_synchronously
                      if (!context.mounted) return;
                      context.push("/compare", extra: (
                        [course.name ?? "unknown", assignment.name],
                        path
                      ));
                    }
                  }
                }
              }
            },
          ),
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
  final Course course;
  const AssignmentListView({super.key, required this.course});

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
                      .getAnnouncements(widget.course,
                          pageSize: pageSize - sizeCourseWork,
                          token: token?.$1);
          Future<(List<CourseWork>, String?)>? courseWorkJob = reachedLast[1]
              ? null
              : Provider.of<Classroom>(context, listen: false).getCourseWork(
                  widget.course,
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
            AssignmentListItem(course: widget.course, assignment: item));
  }
}
