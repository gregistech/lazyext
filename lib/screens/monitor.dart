import 'package:flutter/material.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:lazyext/google/classroom.dart';
import 'package:lazyext/preferences.dart';
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
      title: "Settings",
      child: GPaginatedListView<String?, Course>(
          getPage: (pageSize, token) =>
              Provider.of<Classroom>(context, listen: false)
                  .getCourses(token: token),
          itemBuilder: (BuildContext context, Course course, int index) =>
              CheckboxListTile(
                title: Text(course.name ?? "unknown"),
                value: false,
                onChanged: (bool? value) {},
              )),
    );
  }
}
