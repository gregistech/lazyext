import 'package:flutter/material.dart' hide Material;
import 'package:googleapis/classroom/v1.dart' hide Assignment;
import 'package:lazyext/background.dart';
import 'package:lazyext/screens/monitor.dart';
import 'package:lazyext/screens/settings.dart';
import 'package:lazyext/widgets/assignment.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'google/classroom.dart';
import 'google/drive.dart';
import 'google/google.dart';
import 'screens/compare.dart';
import 'screens/courses.dart';
import 'screens/assignments.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainWidget());
  ClassroomPDFBackgroundService();
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  @override
  initState() {
    super.initState();
  }

  late final _router = GoRouter(
    initialLocation: "/courses",
    routes: [
      ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) {
            return Scaffold(
              body: child,
              drawer: Drawer(
                  child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(child: Text("Drawer")),
                  ListTile(
                    title: const Text("Courses"),
                    onTap: () {
                      context.go("/courses");
                      context.pop();
                    },
                  ),
                  ListTile(
                    title: const Text("Settings"),
                    onTap: () {
                      context.push("/settings");
                      context.pop();
                    },
                  )
                ],
              )),
            );
          },
          routes: [
            GoRoute(path: "/", redirect: (_, __) => "/courses"),
            GoRoute(
                path: '/courses',
                builder: (context, state) => const CoursesScreen(),
                routes: [
                  GoRoute(
                      path: 'assignments',
                      builder: (context, state) =>
                          AssignmentsScreen(course: state.extra as Course),
                      routes: [
                        GoRoute(
                          path: 'assignment',
                          builder: (context, state) {
                            (Course, Assignment) extra =
                                state.extra as (Course, Assignment);
                            return AssignmentScreen(
                              course: extra.$1,
                              assignment: extra.$2,
                            );
                          },
                        )
                      ]),
                ]),
            GoRoute(
                path: "/settings",
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                      path: "monitor",
                      builder: (context, state) => const MonitorScreen())
                ])
          ]),
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
