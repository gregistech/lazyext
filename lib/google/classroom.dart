import 'package:flutter/material.dart' hide Material;
import 'package:googleapis/classroom/v1.dart';
import 'package:http/http.dart';

import 'google.dart';

class Classroom extends ChangeNotifier {
  final List<String> _scopes = <String>[
    ClassroomApi.classroomAnnouncementsReadonlyScope,
    ClassroomApi.classroomCoursesReadonlyScope,
    ClassroomApi.classroomCourseworkMeReadonlyScope,
  ];
  final Google _google;
  ClassroomApi? _api;

  Classroom(this._google) {
    Future<bool> result = _google.requestScopes(_scopes);
    result.then((bool resullt) async {
      Client? client = await _google.getAuthenticatedClient();
      if (client != null) {
        _api = ClassroomApi(client);
      }
    });
  }

  Future<void> waitForApi() async {
    while (_api == null) {
      await Future.delayed(const Duration(microseconds: 100));
    }
  }

  Future<(List<Course>, String?)> getCourses(
      {int pageSize = 20, String? token}) async {
    await waitForApi();
    ListCoursesResponse? response =
        await _api?.courses.list(pageToken: token, pageSize: pageSize);
    return (response?.courses ?? [], response?.nextPageToken);
  }

  Future<(List<CourseWork>, String?)> getCourseWork(String id,
      {int pageSize = 20, String? token}) async {
    await waitForApi();
    ListCourseWorkResponse? response = await _api?.courses.courseWork
        .list(id, pageToken: token, pageSize: pageSize);
    return (response?.courseWork ?? [], response?.nextPageToken);
  }

  Future<(List<Announcement>, String?)> getAnnouncements(String id,
      {int pageSize = 20, String? token}) async {
    await waitForApi();
    ListAnnouncementsResponse? response = await _api?.courses.announcements
        .list(id, pageToken: token, pageSize: pageSize);
    return (response?.announcements ?? [], response?.nextPageToken);
  }
}
