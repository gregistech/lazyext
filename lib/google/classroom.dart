import 'package:flutter/material.dart' hide Material;
import 'package:googleapis/classroom/v1.dart';
import 'package:http/http.dart';

import 'google.dart';

class Classroom extends GoogleApi<ClassroomApi> with ChangeNotifier {
  @override
  final List<String> scopes = <String>[
    ClassroomApi.classroomAnnouncementsReadonlyScope,
    ClassroomApi.classroomCoursesReadonlyScope,
    ClassroomApi.classroomCourseworkMeReadonlyScope,
  ];

  Classroom(Google google)
      : super(google, (Client client) => ClassroomApi(client));

  Future<(List<Course>, String?)> getCourses(
      {int pageSize = 20, String? token}) async {
    ListCoursesResponse? response = await getResponse(
        () => api?.courses.list(pageToken: token, pageSize: pageSize));
    return (response?.courses ?? [], response?.nextPageToken);
  }

  Future<(List<CourseWork>, String?)> getCourseWork(Course course,
      {int pageSize = 20, String? token}) async {
    String? id = course.id;
    if (id != null) {
      ListCourseWorkResponse? response = await getResponse(() => api
          ?.courses.courseWork
          .list(id, pageToken: token, pageSize: pageSize));
      return (response?.courseWork ?? [], response?.nextPageToken);
    } else {
      return ([] as List<CourseWork>, null);
    }
  }

  Future<(List<Announcement>, String?)> getAnnouncements(Course course,
      {int pageSize = 20, String? token}) async {
    String? id = course.id;
    if (id != null) {
      ListAnnouncementsResponse? response = await getResponse(() => api
          ?.courses.announcements
          .list(id, pageToken: token, pageSize: pageSize));
      return (response?.announcements ?? [], response?.nextPageToken);
    } else {
      return ([] as List<Announcement>, null);
    }
  }
}
