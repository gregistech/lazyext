import 'package:flutter/material.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:lazyext/app/preferences.dart';
import 'package:lazyext/google/classroom.dart';
import 'package:lazyext/widgets/g_paginated_list_view.dart';
import 'package:provider/provider.dart';

import 'screen.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  dynamic prefs = Preferences();

  @override
  Widget build(BuildContext context) {
    return ScreenWidget(
      title: "Courses to fetch",
      child: GPaginatedListView<String?, Course>(
          getPage: (pageSize, token) async =>
              (await Provider.of<Classroom>(context, listen: false)
                      .getCourses(token: token) ??
                  (<Course>[], null)),
          itemBuilder: (BuildContext context, Course course, int index) =>
              FutureBuilder(
                  future: prefs.monitor,
                  builder: (context, AsyncSnapshot<dynamic> snapshot) {
                    return CheckboxListTile(
                      title: Text(course.name ?? "unknown"),
                      value: (snapshot.data ?? "").contains(course.id),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value ?? false) {
                            prefs.monitor =
                                (snapshot.data ?? "") + "${course.id},";
                          } else {
                            prefs.monitor = (snapshot.data ?? "")
                                .replaceAll("${course.id},", "");
                          }
                        });
                      },
                    );
                  })),
    );
  }
}
