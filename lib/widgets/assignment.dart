import 'package:flutter/material.dart' hide Material;
import 'package:go_router/go_router.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:googleapis/drive/v3.dart' hide Drive;
import 'package:intl/intl.dart';
import 'package:lazyext/google/cached_teacher.dart';
import 'package:lazyext/widgets/cached_teacher_pfp.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
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

class AssignmentListItem extends StatefulWidget {
  final Course course;
  final Assignment assignment;
  final void Function(List<Material> selected) onSelectionChanged;
  const AssignmentListItem(
      {super.key,
      required this.course,
      required this.assignment,
      required this.onSelectionChanged});

  @override
  State<AssignmentListItem> createState() => _AssignmentListItemState();
}

class _AssignmentListItemState extends State<AssignmentListItem> {
  List<Material> selected = [];
  late List<Material> materials = widget.assignment.materials
      .where((element) => element.driveFile != null)
      .toList();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CachedTeacher?>(
        future: Provider.of<CachedTeacherProvider>(context, listen: false)
            .getTeacher(widget.course.id ?? "", widget.assignment.creatorId),
        builder: (context, snapshot) {
          CachedTeacher? teacher = snapshot.data;
          return ListTile(
            leading: CachedTeacherProfilePicture(teacher: teacher),
            title: Text(widget.assignment.name.trim()),
            subtitle: Text(
                "${DateFormat.yMMMMEEEEd().format(widget.assignment.creationTime)}${teacher?.name == null ? '' : '\n${teacher?.name}'}"),
            trailing: Checkbox(
                value: selected.isEmpty
                    ? false
                    : (selected.length == materials.length ? true : null),
                onChanged: (bool? value) {
                  setState(() {
                    if (value ?? false) {
                      selected = materials;
                    } else {
                      selected = [];
                    }
                  });
                  widget.onSelectionChanged(selected);
                }),
            onTap: () async {
              await showModalBottomSheet(
                context: context,
                builder: (ctx) {
                  return MultiSelectBottomSheet<Material>(
                    items: materials
                        .map((e) => MultiSelectItem<Material>(
                            e, e.driveFile?.driveFile?.title ?? "Unknown"))
                        .toList(),
                    initialValue: selected,
                    onSelectionChanged: (selection) {
                      setState(() => selected = selection);
                      widget.onSelectionChanged(selected);
                    },
                    cancelText: null,
                    confirmText: null,
                  );
                },
              );
            },
          );
        });
  }
}

/*class AssignmentView extends StatefulWidget {
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
        FutureBuilder<CachedTeacher?>(
            future: Provider.of<CachedTeacherProvider>(context, listen: false)
                .getTeacher(
                    widget.course.id ?? "", widget.assignment.creatorId),
            builder:
                (BuildContext context, AsyncSnapshot<CachedTeacher?> snapshot) {
              CachedTeacher? teacher = snapshot.data;
              return ListTile(
                isThreeLine: true,
                leading: CachedTeacherProfilePicture(teacher: teacher),
                title: Text(widget.assignment.name.trim()),
                subtitle: Text(
                  "${teacher?.name == null ? "" : "- ${teacher?.name}"}${widget.assignment.text.isEmpty ? "" : '\n\n${widget.assignment.text}'}",
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
}*/

class AssignmentListView extends StatefulWidget {
  final Course course;
  const AssignmentListView(
      {super.key, required this.course, required this.onSelectionChanged});
  final void Function(List<Material> selected) onSelectionChanged;

  @override
  State<AssignmentListView> createState() => _AssignmentListViewState();
}

class _AssignmentListViewState extends State<AssignmentListView> {
  List<bool> reachedLast = [false, false];
  List<String> ids = [];
  Map<String, List<Material>> selected = {};

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
            AssignmentListItem(
              course: widget.course,
              assignment: item,
              onSelectionChanged: (selection) {
                selected[item.id] = selection;
                widget.onSelectionChanged(selected.values.fold(
                    [], (previousValue, element) => previousValue + element));
              },
            ));
  }
}
