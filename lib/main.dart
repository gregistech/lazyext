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
import 'screens/login.dart';
import 'screens/assignments.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MainWidget());
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  Future<void> initPlatformState() async {
    int status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            startOnBoot: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.ANY), (String taskId) async {
      print("[BackgroundFetch] Event received $taskId");
      Google google = Google();
      Classroom classroom = Classroom(google);
      print((await classroom.getCourses()).$1[0].name);
      BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      BackgroundFetch.finish(taskId);
    });
    print('[BackgroundFetch] configure success: $status');
    if (!mounted) return;
  }

  String? authRedirect(BuildContext context, GoRouterState state) {
    return Provider.of<Google>(context, listen: false).account == null
        ? "/login"
        : null;
  }

  late final _router = GoRouter(
    initialLocation: "/courses",
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
          path: '/courses',
          builder: (context, state) => const CoursesScreen(),
          redirect: authRedirect),
      GoRoute(
          path: '/course/assignments',
          builder: (context, state) =>
              AssignmentsScreen(course: state.extra as Course),
          redirect: authRedirect),
      GoRoute(
          path: '/course/assignment',
          builder: (context, state) => AssignmentScreen(
                assignment: state.extra as Assignment,
              )),
      GoRoute(
          path: '/compare',
          builder: (context, state) =>
              CompareScreen(path: state.extra as String)),
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
