import 'package:flutter/material.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:lazyext/google/classroom.dart';
import 'package:lazyext/widgets/g_paginated_list_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screen.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
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
                  future: SharedPreferences.getInstance(),
                  builder:
                      (context, AsyncSnapshot<SharedPreferences> snapshot) {
                    return CheckboxListTile(
                      title: Text(course.name ?? "unknown"),
                      value: (snapshot.data?.getString("monitor") ?? "")
                          .contains(course.id ?? "unknown"),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value ?? false) {
                            snapshot.data?.setString("monitor",
                                "${snapshot.data?.getString("monitor") ?? ""}${course.id},");
                          } else {
                            snapshot.data?.setString(
                                "monitor",
                                (snapshot.data?.getString("monitor") ?? "")
                                    .replaceAll("${course.id},", ""));
                          }
                        });
                      },
                    );
                  })),
    );
  }
}
