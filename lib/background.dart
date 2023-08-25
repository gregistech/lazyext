import 'package:background_fetch/background_fetch.dart';
import 'package:googleapis/classroom/v1.dart' hide Assignment;
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:lazyext/android_file_storage.dart';
import 'package:lazyext/google/classroom.dart';
import 'package:lazyext/google/drive.dart';
import 'package:lazyext/google/google.dart';
import 'package:lazyext/pdf/extractor.dart';
import 'package:lazyext/pdf/merger.dart';
import 'package:lazyext/pdf/storage.dart';
import 'package:lazyext/preferences.dart';
import 'package:lazyext/widgets/assignment.dart';
import 'package:mupdf_android/mupdf_android.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ClassroomPDFBackgroundService {
  ClassroomPDFBackgroundService() {
    BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            enableHeadless: true,
            startOnBoot: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.ANY), (String taskId) async {
      await checkForNewAssignment();
      BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      BackgroundFetch.finish(taskId);
    });
    BackgroundFetch.start();
    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  }

  @pragma('vm:entry-point')
  static void backgroundFetchHeadlessTask(HeadlessTask task) async {
    String taskId = task.taskId;
    bool isTimeout = task.timeout;
    if (isTimeout) {
      BackgroundFetch.finish(taskId);
      return;
    }
    await checkForNewAssignment();
    BackgroundFetch.finish(taskId);
  }

  static Future<List<Course>?> getMonitoredCourses(
      dynamic prefs, Classroom classroom) async {
    List<Course> courses = await classroom.getAll(classroom.getCourses);
    List<String>? monitored = ((await prefs.monitor) as String?)?.split(",");
    if (monitored != null) {
      return courses.where((Course element) {
        for (String id in monitored) {
          if (id == element.id) {
            return true;
          }
        }
        return false;
      }).toList();
    }
    return null;
  }

  static List<Assignment> combineIntoAssignments(
      List<CourseWork> courseWork, List<Announcement> announcements) {
    List<Assignment> assignments = [];
    for (Announcement announcement in announcements) {
      assignments.add(Assignment.fromAnnouncement(announcement));
    }
    for (CourseWork elem in courseWork) {
      assignments.add(Assignment.fromCourseWork(elem));
    }
    return assignments;
  }

  static Future<List<Assignment>> getNewestAssignments(
      Classroom classroom, Course course) async {
    List<Announcement> announcements =
        (await classroom.getAnnouncements(course, pageSize: 1)).$1;
    List<CourseWork> courseWork =
        (await classroom.getCourseWork(course, pageSize: 1)).$1;
    return combineIntoAssignments(courseWork, announcements);
  }

  static Future<List<Assignment>> getCutOffynamicAssignments(
      Classroom classroom, Course course, String cutoffDate) async {
    List<Announcement> announcements = await classroom.getAll((
            {int pageSize = 20, String? token}) async =>
        classroom.getAnnouncements(course,
            pageSize: pageSize, token: token, cutoffDate: cutoffDate));
    List<CourseWork> courseWork = await classroom.getAll((
            {int pageSize = 20, String? token}) async =>
        classroom.getCourseWork(course,
            pageSize: pageSize, token: token, cutoffDate: cutoffDate));
    return combineIntoAssignments(courseWork, announcements);
  }

  static Future<List<Assignment>> getTargetAssignments(
      dynamic prefs, Classroom classroom, Course course) async {
    if (await prefs.lastAssignment == null) {
      return getNewestAssignments(classroom, course);
    } else {
      return getCutOffynamicAssignments(
          classroom, course, await prefs.lastAssignment);
    }
  }

  static Future<List<Exercise>?> assignmentToExercises(
      Drive driveApi, Assignment assignment) async {
    ExerciseExtractor extractor = ExerciseExtractor();
    for (Material material in assignment.materials) {
      DriveFile? driveFile = material.driveFile?.driveFile;
      if (driveFile != null) {
        drive.File? file = await driveApi.driveFileToFile(driveFile);
        if (file != null) {
          drive.File? gdoc = await driveApi.fileToGoogleDoc(file);
          if (gdoc != null) {
            drive.Media? pdf = await driveApi.fileToPdf(gdoc);
            if (pdf != null) {
              String? path = await driveApi.downloadMedia(pdf,
                  "${(await getTemporaryDirectory()).path}/${const Uuid().v4()}.pdf");
              if (path != null) {
                File file = File(path);
                return (await extractor.getExerciseCollection(file)).$2;
              }
            }
          }
        }
      }
    }
    return null;
  }

  static Future<void> checkForNewAssignment() async {
    Google google = Google();
    Classroom classroom = Classroom(google);
    Drive driveApi = Drive(google);
    dynamic prefs = Preferences();

    List<Course>? courses = await getMonitoredCourses(prefs, classroom);
    if (courses != null) {
      for (Course course in courses) {
        List<Assignment> assignments =
            await getTargetAssignments(prefs, classroom, course);
        prefs.lastAssignment = DateTime.now().toIso8601String();

        for (Assignment assignment in assignments) {
          Merger merger = PracticeMerger();
          List<Exercise>? exercises =
              await assignmentToExercises(driveApi, assignment);
          if (exercises != null) {
            PDFDocument pdf = await merger.exercisesToPDFDocument(exercises);
            Storage? storage = await AndroidFileStorage().storage;
            await storage
                ?.savePDF([course.name ?? "unknown", assignment.name], pdf);
          }
        }
      }
    }
  }
}
