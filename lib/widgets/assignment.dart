import 'package:flutter/material.dart' hide Material;
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:go_router/go_router.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:googleapis/drive/v3.dart' hide Drive;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import '../google/classroom.dart';
import '../google/drive.dart';
import 'g_paginated_list_view.dart';

class Assignment implements Comparable<Assignment> {
  late final String id;
  late final String creatorId;
  late final String name;
  late final String text;
  late final List<Material> materials;
  late final DateTime creationTime;

  Assignment(this.id, this.name, this.text, this.materials, this.creationTime);
  Assignment.fromAnnouncement(Announcement announcement) {
    id = announcement.id ?? "";
    creatorId = announcement.creatorUserId ?? "";
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
    creatorId = courseWork.creatorUserId ?? "";
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
    return FutureBuilder<Teacher?>(
        future: Provider.of<Classroom>(context, listen: false)
            .getTeacher(course.id ?? "", assignment.creatorId),
        builder: (context, snapshot) {
          Teacher? teacher = snapshot.data;
          return ListTile(
            leading: ProfilePicture(
              name: teacher?.profile?.name?.fullName ?? "",
              img: teacher?.profile?.photoUrl == null
                  ? null
                  : "https:${teacher?.profile?.photoUrl}",
              radius: 21,
              fontsize: 21,
            ),
            title: Text(assignment.name.trim()),
            subtitle: Text(
                "${DateFormat.yMMMMEEEEd().format(assignment.creationTime)}${teacher?.profile?.name?.fullName == null ? '' : '\n${teacher?.profile?.name?.fullName}'}"),
            trailing: Text(assignment.materials.length.toString()),
            onTap: () {
              context.push("/courses/assignments/assignment",
                  extra: (course, assignment));
            },
          );
        });
  }
}

class AssignmentView extends StatefulWidget {
  final Course course;
  final Assignment assignment;
  const AssignmentView(
      {super.key, required this.course, required this.assignment});

  @override
  State<AssignmentView> createState() => _AssignmentViewState();
}

class _AssignmentViewState extends State<AssignmentView> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    List<Widget> materials = [];
    for (Material material in widget.assignment.materials) {
      DriveFile? driveFile = material.driveFile?.driveFile;
      if (driveFile != null) {
        materials.add(FutureBuilder(
          future: Provider.of<Drive>(context, listen: false)
              .driveFileToFile(driveFile),
          builder: (BuildContext context, AsyncSnapshot<File?> snapshot) =>
              ListTile(
            leading: const Icon(Icons.open_in_new_rounded),
            title: Text(snapshot.data?.name ?? "UNKNOWN"),
            onTap: () async {
              if (!loading) {
                setState(() {
                  loading = true;
                });
                File? file = snapshot.data;
                if (file != null) {
                  File? gdoc = await Provider.of<Drive>(context, listen: false)
                      .fileToGoogleDoc(file);
                  if (gdoc != null) {
                    // ignore: use_build_context_synchronously
                    if (!context.mounted) return;
                    Media? pdf =
                        await Provider.of<Drive>(context, listen: false)
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
                        loading = false;
                        context.push("/compare", extra: (
                          [
                            widget.course.name ?? "unknown",
                            widget.assignment.name
                          ],
                          path
                        ));
                      }
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
        FutureBuilder<Teacher?>(
            future: Provider.of<Classroom>(context, listen: false).getTeacher(
                widget.course.id ?? "", widget.assignment.creatorId),
            builder: (BuildContext context, AsyncSnapshot<Teacher?> snapshot) {
              Teacher? teacher = snapshot.data;
              return ListTile(
                isThreeLine: true,
                leading: ProfilePicture(
                  name: teacher?.profile?.name?.fullName ?? "",
                  img: teacher?.profile?.photoUrl == null
                      ? null
                      : "https:${teacher?.profile?.photoUrl}",
                  radius: 21,
                  fontsize: 21,
                ),
                title: Text(widget.assignment.name.trim()),
                subtitle: Text(
                  "${teacher?.profile?.name?.fullName == null ? "" : "- ${teacher?.profile?.name?.fullName}"}${widget.assignment.text.isEmpty ? "" : '\n\n${widget.assignment.text}'}",
                ),
              );
            }),
        Visibility(
            visible: loading,
            child: const LinearProgressIndicator(value: null)),
        Expanded(
          child: ListView(
            children: materials,
          ),
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
          Future<(List<Announcement>, String?)?>? announcementJob =
              reachedLast[0]
                  ? null
                  : Provider.of<Classroom>(context, listen: false)
                      .getAnnouncements(widget.course,
                          pageSize: pageSize - sizeCourseWork,
                          token: token?.$1);
          Future<(List<CourseWork>, String?)?>? courseWorkJob = reachedLast[1]
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
            assignments.where((Assignment assignment) {
              for (Material material in assignment.materials) {
                if (material.driveFile != null) {
                  return true;
                }
              }
              return false;
            }).toList(),
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
