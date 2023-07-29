import 'package:flutter/material.dart' hide Material;
import 'package:googleapis/classroom/v1.dart';

import 'google.dart';

class Classroom extends GoogleApi<ClassroomApi> with ChangeNotifier {
  @override
  final List<String> scopes = <String>[
    ClassroomApi.classroomAnnouncementsReadonlyScope,
    ClassroomApi.classroomCoursesReadonlyScope,
    ClassroomApi.classroomCourseworkMeReadonlyScope,
  ];

  Classroom(super.google, super.apiCreator);

  Future<(List<Course>, String?)> getCourses(
      {int pageSize = 20, String? token}) async {
    await waitForApi();
    ListCoursesResponse? response =
        await api?.courses.list(pageToken: token, pageSize: pageSize);
    return (response?.courses ?? [], response?.nextPageToken);
  }

  Future<(List<CourseWork>, String?)> getCourseWork(String id,
      {int pageSize = 20, String? token}) async {
    await waitForApi();
    ListCourseWorkResponse? response = await api?.courses.courseWork
        .list(id, pageToken: token, pageSize: pageSize);
    return (response?.courseWork ?? [], response?.nextPageToken);
  }

  Future<(List<Announcement>, String?)> getAnnouncements(String id,
      {int pageSize = 20, String? token}) async {
    await waitForApi();
    ListAnnouncementsResponse? response = await api?.courses.announcements
        .list(id, pageToken: token, pageSize: pageSize);
    return (response?.announcements ?? [], response?.nextPageToken);
  }
}
