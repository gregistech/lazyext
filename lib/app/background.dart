import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis/classroom/v1.dart' hide Assignment;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:jni/jni.dart';
import 'package:lazyext/app/android_file_storage.dart';
import 'package:lazyext/app/document_source.dart';
import 'package:lazyext/google/cached_teacher.dart';
import 'package:lazyext/google/classroom.dart';
import 'package:lazyext/google/drive.dart';
import 'package:lazyext/google/google.dart';
import 'package:lazyext/pdf/mapper.dart';
import 'package:lazyext/pdf/extractor.dart';
import 'package:lazyext/pdf/storage.dart';
import 'package:mupdf_android/mupdf_android.dart' as mupdf;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum NotificationAction {
  noStorageRoot("storageroot", "No Storage Root found",
      "Set a Storage Root for background fetching to work properly!"),
  googleSignIn("googlesignin", "Sign-in to Google",
      "Sign-in to Google for background fetching to work properly!");

  const NotificationAction(this.action, this.title, this.desc);

  final String action;
  final String title;
  final String desc;
}

class ClassroomPDFNotifications {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings("@mipmap/ic_launcher")));
  }

  Future<NotificationAction?> getLaunchReason() async {
    NotificationAppLaunchDetails? details =
        await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      String? payload = details?.notificationResponse?.payload;
      try {
        return NotificationAction.values.firstWhere(
            (NotificationAction element) => element.action == payload);
      } on StateError {
        return null;
      }
    } else {
      return null;
    }
  }

  Future<void> showProcessingNotification({bool show = true}) async {
    const NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails("process", "process",
            showProgress: true,
            indeterminate: true,
            ongoing: true,
            importance: Importance.min));
    if (show) {
      await _plugin.show(
          0, "Background assignments", "Processing assignments...", details);
    } else {
      await _plugin.cancel(0);
    }
  }

  Future<void> _showProcessedNotification(Document document) async {
    const NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails("processed", "processed",
            importance: Importance.high));
    await _plugin.show(document.hashCode, "Processed assignment",
        await document.title, details);
  }

  Future<void> showProcessedNotifications(List<Document> documents) async {
    for (Document document in documents) {
      await _showProcessedNotification(document);
    }
  }

  Future<void> _showActionNotification(NotificationAction action) async {
    NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(action.action, action.action,
            importance: Importance.max));
    await _plugin.show(1, action.title, action.desc, details,
        payload: action.action);
  }

  Future<void> showNoStorageRootNotification() async {
    await _showActionNotification(NotificationAction.noStorageRoot);
  }

  Future<void> showSignInNotification() async {
    await _showActionNotification(NotificationAction.googleSignIn);
  }

  Future<bool> requestPermission() async {
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestPermission() ??
        false;
  }
}

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
      final notifications = ClassroomPDFNotifications();
      notifications.initialize();
      await checkForNewAssignment(notifications);
      BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      BackgroundFetch.finish(taskId);
    });

    BackgroundFetch.start();
    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
    ClassroomPDFNotifications().requestPermission();
  }

  @pragma('vm:entry-point')
  static void backgroundFetchHeadlessTask(HeadlessTask task) async {
    String taskId = task.taskId;
    bool isTimeout = task.timeout;
    if (isTimeout) {
      BackgroundFetch.finish(taskId);
      return;
    }
    final notifications = ClassroomPDFNotifications();
    await notifications.initialize();
    await checkForNewAssignment(notifications);
    BackgroundFetch.finish(taskId);
  }

  static Future<List<Course>?> getMonitoredCourses(
      SharedPreferences prefs, Classroom classroom) async {
    List<Course> courses = await classroom.getAll(classroom.getCourses);
    List<String>? monitored = prefs.getString("monitor")?.split(",");
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

  static Future<List<Document>> combineIntoAssignments(
      Classroom classroom,
      Drive drive,
      CachedTeacherProvider provider,
      Course course,
      List<CourseWork> courseWork,
      List<Announcement> announcements) async {
    List<Document> assignments = [];
    for (Announcement announcement in announcements) {
      /*assignments.addAll((await Assignment.fromAnnouncement(announcement)
              .toDocumentEntity(classroom, drive, provider, course)
              .entities
              .toList())
          .whereType<Document>());*/
    }
    for (CourseWork elem in courseWork) {
      /*assignments.addAll((await Assignment.fromCourseWork(elem)
              .toDocumentEntity(classroom, drive, provider, course)
              .entities
              .toList())
          .whereType<Document>());*/
    }
    return assignments;
  }

  static Future<List<Document>> getNewestAssignments(Classroom classroom,
      Drive drive, CachedTeacherProvider provider, Course course) async {
    List<Announcement> announcements =
        (await classroom.getAnnouncements(course, pageSize: 1))?.$1 ?? [];
    List<CourseWork> courseWork =
        (await classroom.getCourseWork(course, pageSize: 1))?.$1 ?? [];
    return combineIntoAssignments(
        classroom, drive, provider, course, courseWork, announcements);
  }

  static Future<List<Document>> getCutOffynamicAssignments(
      Classroom classroom,
      Drive drive,
      Course course,
      CachedTeacherProvider provider,
      String cutoffDate) async {
    List<Announcement> announcements = await classroom.getAll((
            {int pageSize = 20, String? token}) async =>
        classroom.getAnnouncements(course,
            pageSize: pageSize, token: token, cutoffDate: cutoffDate));
    List<CourseWork> courseWork = await classroom.getAll((
            {int pageSize = 20, String? token}) async =>
        classroom.getCourseWork(course,
            pageSize: pageSize, token: token, cutoffDate: cutoffDate));
    return combineIntoAssignments(
        classroom, drive, provider, course, courseWork, announcements);
  }

  static Future<List<Document>> getTargetAssignments(
      SharedPreferences prefs,
      Classroom classroom,
      Drive drive,
      CachedTeacherProvider provider,
      Course course) async {
    String? lastAssignment = RegExp("specific_string:[^,]+,")
        .firstMatch(prefs.getString("lastAssignment") ?? "")
        ?.group(0);
    if (lastAssignment == null) {
      return getNewestAssignments(classroom, drive, provider, course);
    } else {
      return getCutOffynamicAssignments(
          classroom, drive, course, provider, lastAssignment);
    }
  }

  static Future<mupdf.PDFDocument?> assignmentToDocument(
      Drive driveApi, Assignment assignment) async {
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
                return mupdf.Document.openDocument(path.toJString())
                    .toPDFDocument();
              }
            }
          }
        }
      }
    }
    return null;
  }

  static Future<void> checkForNewAssignment(
      ClassroomPDFNotifications notifications) async {
    Storage? storage;
    try {
      storage = await AndroidFileStorage().storage;
    } on MissingPluginException {
      await notifications.showNoStorageRootNotification();
      return;
    }
    await notifications.showProcessingNotification();
    await dotenv.load();
    String? clientId;
    clientId = dotenv.env["CLIENTID"];
    clientId ??=
        "374861372817-tltgqakn1qs9up0e8922p5l49gpra54n.apps.googleusercontent.com";

    Google google = Google(clientId: clientId);
    Classroom classroom = Classroom(google);
    Drive driveApi = Drive(google);
    CachedTeacherProvider provider = CachedTeacherProvider(classroom);
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<Course>? courses = await getMonitoredCourses(prefs, classroom);
    if (courses != null) {
      for (Course course in courses) {
        List<Document> documents = await getTargetAssignments(
            prefs, classroom, driveApi, provider, course);
        prefs.setString(
            "lastAssignment",
            (prefs.getString("lastAssignment") ?? "")
                .replaceAll(RegExp("[^:]+:[^,]+,"), ""));
        prefs.setString("lastAssignment",
            "${prefs.getString("lastAssignment") ?? ""}${course.id ?? "unknown"}:${DateTime.now().toIso8601String()},");
        List<Document> done = [];
        for (Document document in documents) {
          mupdf.PDFDocument? pdf = await document.document;
          if (pdf != null) {
            List<Exercise> exercises =
                await ExerciseMapper().documentToExercises(pdf);
            Extractor merger = PracticeExtractor(
                exercises.first.document.pages.first.getBounds1());
            mupdf.PDFDocument? merged =
                await merger.exercisesToDocument(exercises);
            if (merged != null) {
              storage?.savePDF(
                  [course.name ?? "unknown", await document.title], merged);
              done.add(document);
            }
          }
        }
        notifications.showProcessedNotifications(done);
      }
    }
    await notifications.showProcessingNotification(show: false);
  }
}
