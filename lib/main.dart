import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/classroom/v1.dart' hide Assignment;
import 'package:lazyext/widgets/assignment.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

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
  print("Checking for assignment...");
  Google google = Google();
  Classroom classroom = Classroom(google);
  print((await classroom.getCourses()).$1[0].name);
  print("Done.");
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
