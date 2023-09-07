import 'package:flutter/material.dart' hide Material;
import 'package:googleapis/classroom/v1.dart' hide Assignment;
import 'package:lazyext/app/background.dart';
import 'package:lazyext/app/dynamic_color_scheme.dart';
import 'package:lazyext/app/theme.dart';
import 'package:lazyext/google/cached_teacher.dart';
import 'package:lazyext/screens/googlesignin.dart';
import 'package:lazyext/screens/monitor.dart';
import 'package:lazyext/screens/settings.dart';
import 'package:lazyext/screens/storageroot.dart';
import 'package:lazyext/widgets/drawer.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'google/classroom.dart';
import 'google/drive.dart';
import 'google/google.dart';
import 'screens/compare.dart';
import 'screens/courses.dart';
import 'screens/assignments.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(
      MainWidget(action: await ClassroomPDFNotifications().getLaunchReason()));
  ClassroomPDFBackgroundService();
}

class MainWidget extends StatefulWidget {
  final NotificationAction? action;
  const MainWidget({super.key, this.action});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  @override
  initState() {
    super.initState();
  }

  late final _router = GoRouter(
    initialLocation: widget.action == null ? "/courses" : "/settings",
    routes: [
      ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) {
            return Scaffold(
              body: child,
              drawer: const MainDrawer(),
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
                  ),
                ]),
            GoRoute(
                path: "/settings",
                builder: (context, state) =>
                    SettingsScreen(action: widget.action),
                routes: [
                  GoRoute(
                      path: "monitor",
                      builder: (context, state) => const MonitorScreen()),
                  GoRoute(
                      path: "storageroot",
                      builder: (context, state) => const StorageRootScreen()),
                  GoRoute(
                      path: "googlesignin",
                      builder: (context, state) => const GoogleSignInScreen())
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
            create: (_) => Google(
                clientId: dotenv.env["CLIENTID"] ?? "",
                scopes: (Classroom.staticScopes.toList() +
                        Drive.staticScopes.toList())
                    .toSet()),
          ),
          ListenableProxyProvider<Google, Classroom>(
              update: (_, google, __) => Classroom(google)),
          ListenableProxyProvider<Classroom, CachedTeacherProvider>(
              update: (_, classroom, __) => CachedTeacherProvider(classroom)),
          ListenableProxyProvider<Google, Drive>(
              update: (_, google, __) => Drive(google)),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider())
        ],
        child: DynamicColorScheme(
          title: "LazyEXT",
          routerConfig: _router,
        ));
  }
}
