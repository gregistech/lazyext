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

  static Future<void> checkForNewAssignment() async {
    Google google = Google();
    Classroom classroom = Classroom(google);
    List<Course> courses = await classroom.getAll(classroom.getCourses);
    dynamic prefs = Preferences();
    List<String>? monitored = ((await prefs.monitor) as String?)?.split(",");
    if (monitored != null) {
      courses = courses.where((Course element) {
        for (String id in monitored) {
          if (id == element.id) {
            return true;
          }
        }
        return false;
      }).toList();
      for (Course course in courses) {
        List<Announcement> announcements =
            (await classroom.getAnnouncements(course)).$1;
        Assignment? lastAnnouncement;
        if (announcements.isNotEmpty) {
          lastAnnouncement = Assignment.fromAnnouncement(announcements[0]);
        }
        List<CourseWork> courseWork =
            (await classroom.getCourseWork(course)).$1;
        Assignment? lastCourseWork;
        if (courseWork.isNotEmpty) {
          lastCourseWork = Assignment.fromCourseWork(courseWork[0]);
        }

        Assignment? lastAssignment;
        if (lastAnnouncement != null && lastCourseWork != null) {
          lastAssignment = lastCourseWork.compareTo(lastAnnouncement) >= 0
              ? lastCourseWork
              : lastAnnouncement;
        } else {
          lastAssignment = lastCourseWork ?? lastAnnouncement;
        }
        if (lastAssignment != null) {
          if (!((await prefs.doneAssignments) as String? ?? "")
              .contains(lastAssignment.id)) {
            prefs.doneAssignments =
                "${(await prefs.doneAssignments) as String? ?? ""}${lastAssignment.id},";
            List<Exercise> exercises = [];
            Drive driveApi = Drive(google);
            ExerciseExtractor extractor = ExerciseExtractor();
            for (Material material in lastAssignment.materials) {
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
                        exercises.addAll(
                            (await extractor.getExerciseCollection(file)).$2);
                      }
                    }
                  }
                }
              }
            }
            Merger merger = PracticeMerger();
            PDFDocument pdf = await merger.exercisesToPDFDocument(exercises);
            Storage? storage = await AndroidFileStorage().storage;
            await storage
                ?.savePDF([course.name ?? "unknown", lastAssignment.name], pdf);
          }
        }
      }
    }
  }
}
