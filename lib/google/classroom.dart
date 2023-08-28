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
    ClassroomApi.classroomRostersReadonlyScope,
    ClassroomApi.classroomProfileEmailsScope,
    ClassroomApi.classroomProfilePhotosScope
  ];

  Classroom(Google google)
      : super(google, (Client client) => ClassroomApi(client));

  Future<(List<Course>, String?)?> getCourses(
      {int pageSize = 20, String? token, String? cutoffDate}) async {
    ListCoursesResponse? response =
        await list((ClassroomApi api) => api.courses.list);
    String? nextPageToken = response?.nextPageToken;
    if (nextPageToken != null) {
      nextPageToken = DateTime.parse(response?.courses?.last.creationTime ?? "")
                  .compareTo(DateTime.parse(cutoffDate ?? "1970-01-01")) <
              0
          ? null
          : nextPageToken;
      if (nextPageToken == null) {
        response?.courses = response.courses
            ?.where((Course element) =>
                DateTime.parse(element.creationTime ?? "")
                    .compareTo(DateTime.parse(cutoffDate ?? "1970-01-01")) >=
                0)
            .toList();
      }
    }
    List<Course>? result = response?.courses;
    return result == null ? null : (result, nextPageToken);
  }

  Future<Teacher?> getTeacher(String courseId, String teacherId) async {
    return getResponse(
        (ClassroomApi api) => api.courses.teachers.get(courseId, teacherId));
  }

  Future<(List<CourseWork>, String?)?> getCourseWork(Course course,
      {int pageSize = 20, String? token, String? cutoffDate}) async {
    String? id = course.id;
    if (id != null) {
      ListCourseWorkResponse? response = await list(
          (ClassroomApi api) => api.courses.courseWork.list,
          positional: [id]);
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
      List<CourseWork>? result = response?.courseWork;
      return result == null ? null : (result, nextPageToken);
    } else {
      return ([] as List<CourseWork>, null);
    }
  }

  Future<(List<Announcement>, String?)?> getAnnouncements(Course course,
      {int pageSize = 20, String? token, String? cutoffDate}) async {
    String? id = course.id;
    if (id != null) {
      ListAnnouncementsResponse? response = await list(
          (ClassroomApi api) => api.courses.announcements.list,
          positional: [id]);
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
      List<Announcement>? result = response?.announcements;
      return result == null ? null : (result, nextPageToken);
    } else {
      return ([] as List<Announcement>, null);
    }
  }
}
