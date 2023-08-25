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
      {int pageSize = 20, String? token, String? cutoffDate}) async {
    String? id = course.id;
    if (id != null) {
      ListCourseWorkResponse? response = await getResponse(() => api
          ?.courses.courseWork
          .list(id, pageToken: token, pageSize: pageSize));
      String? nextPageToken = response?.nextPageToken;
      if (nextPageToken != null) {
        nextPageToken =
            DateTime.parse(response?.courseWork?.last.creationTime ?? "")
                        .compareTo(DateTime.parse(cutoffDate ?? "1970-01-01")) <
                    0
                ? null
                : nextPageToken;
        if (nextPageToken == null) {
          response?.courseWork = response.courseWork
              ?.where((CourseWork element) =>
                  DateTime.parse(element.creationTime ?? "")
                      .compareTo(DateTime.parse(cutoffDate ?? "1970-01-01")) >=
                  0)
              .toList();
        }
      }
      return (response?.courseWork ?? [], nextPageToken);
    } else {
      return ([] as List<CourseWork>, null);
    }
  }

  Future<(List<Announcement>, String?)> getAnnouncements(Course course,
      {int pageSize = 20, String? token, String? cutoffDate}) async {
    String? id = course.id;
    if (id != null) {
      ListAnnouncementsResponse? response = await getResponse(() => api
          ?.courses.announcements
          .list(id, pageToken: token, pageSize: pageSize));
      String? nextPageToken = response?.nextPageToken;
      if (nextPageToken != null) {
        nextPageToken =
            DateTime.parse(response?.announcements?.last.creationTime ?? "")
                        .compareTo(DateTime.parse(cutoffDate ?? "1970-01-01")) <
                    0
                ? null
                : nextPageToken;
        if (nextPageToken == null) {
          response?.announcements = response.announcements
              ?.where((Announcement element) =>
                  DateTime.parse(element.creationTime ?? "")
                      .compareTo(DateTime.parse(cutoffDate ?? "1970-01-01")) >=
                  0)
              .toList();
        }
      }
      return (response?.announcements ?? [], nextPageToken);
    } else {
      return ([] as List<Announcement>, null);
    }
  }
}
