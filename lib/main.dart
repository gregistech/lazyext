import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:googleapis/classroom/v1.dart' hide Assignment;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:lazyext/android_file_storage.dart';
import 'package:lazyext/pdf/extractor.dart';
import 'package:lazyext/pdf/merger.dart';
import 'package:lazyext/pdf/storage.dart';
import 'package:lazyext/preferences.dart';
import 'package:lazyext/widgets/assignment.dart';
import 'package:mupdf_android/mupdf_android.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'google/classroom.dart';
import 'google/drive.dart';
import 'google/google.dart';
import 'screens/compare.dart';
import 'screens/courses.dart';
import 'screens/assignments.dart';

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    BackgroundFetch.finish(taskId);
    return;
  }
  await checkForNewAssignment();
  BackgroundFetch.finish(taskId);
}

Future<void> checkForNewAssignment() async {
  Google google = Google();
  Classroom classroom = Classroom(google);
  List<Course> courses = await classroom.getAll(classroom.getCourses);
  courses = courses
      .where((Course element) => element.name?.contains("matematika") ?? false)
      .toList();
  for (Course course in courses) {
    List<Announcement> announcements =
        (await classroom.getAnnouncements(course)).$1;
    Assignment? lastAnnouncement;
    if (announcements.isNotEmpty) {
      lastAnnouncement = Assignment.fromAnnouncement(announcements[0]);
    }
    List<CourseWork> courseWork = (await classroom.getCourseWork(course)).$1;
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
      dynamic prefs = Preferences();
      if (lastAssignment.id != prefs.lastAssignment) {
        prefs.lastAssignment = lastAssignment.id;
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainWidget());
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  @override
  initState() {
    initPlatformState();
    super.initState();
  }

  Future<void> initPlatformState() async {
    await BackgroundFetch.configure(
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
    if (!mounted) return;
    BackgroundFetch.start();
  }

  late final _router = GoRouter(
    initialLocation: "/courses",
    routes: [
      GoRoute(
          path: '/courses', builder: (context, state) => const CoursesScreen()),
      GoRoute(
          path: '/course/assignments',
          builder: (context, state) =>
              AssignmentsScreen(course: state.extra as Course)),
      GoRoute(
        path: '/course/assignment',
        builder: (context, state) {
          (Course, Assignment) extra = state.extra as (Course, Assignment);
          return AssignmentScreen(
            course: extra.$1,
            assignment: extra.$2,
          );
        },
      ),
      GoRoute(
          path: '/compare',
          builder: (context, state) {
            (List<String>, String) extra =
                state.extra as (List<String>, String);
            return CompareScreen(dest: extra.$1, path: extra.$2);
          }),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Google>(
          create: (_) => Google(),
        ),
        ListenableProxyProvider<Google, Classroom>(
            update: (_, google, __) => Classroom(google)),
        ListenableProxyProvider<Google, Drive>(
            update: (_, google, __) => Drive(google))
      ],
      child: MaterialApp.router(
        title: 'LazyExt',
        theme: ThemeData(
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}
