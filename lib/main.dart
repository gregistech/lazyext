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

class MainWidget extends StatelessWidget {
  MainWidget({super.key});

  String? authRedirect(BuildContext context, GoRouterState state) {
    return Provider.of<Google>(context, listen: false).account == null
        ? "/login"
        : null;
  }

  late final _router = GoRouter(
    initialLocation: "/course",
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
