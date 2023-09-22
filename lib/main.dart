import 'package:flutter/material.dart' hide Material;
import 'package:lazyext/app/background.dart';
import 'package:lazyext/app/document_source.dart';
import 'package:lazyext/app/drawer_provider.dart';
import 'package:lazyext/app/dynamic_color_scheme.dart';
import 'package:lazyext/app/theme.dart';
import 'package:lazyext/google/cached_teacher.dart';
import 'package:lazyext/google/oauth.dart';
import 'package:lazyext/screens/documents.dart';
import 'package:lazyext/screens/googlesignin.dart';
import 'package:lazyext/screens/monitor.dart';
import 'package:lazyext/screens/settings.dart';
import 'package:lazyext/screens/storageroot.dart';
import 'package:lazyext/widgets/drawer.dart';
import 'package:mupdf_android/mupdf_android.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'google/classroom.dart';
import 'google/drive.dart';
import 'google/google.dart';
import 'screens/compare.dart';

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
    initialLocation: widget.action == null ? "/sources" : "/settings",
    routes: [
      ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) {
            return Scaffold(
              body: child,
              drawer: const MainDrawer(),
            );
          },
          routes: [
            GoRoute(path: "/", redirect: (_, __) => "/sources"),
            GoRoute(
                path: '/sources',
                builder: (context, state) {
                  DocumentEntity? data = state.extra as DocumentEntity?;
                  data ??= ClassroomRootDocumentEntity(
                      null,
                      Provider.of<Classroom>(context, listen: false),
                      Provider.of<CachedTeacherProvider>(context,
                          listen: false),
                      Provider.of<Drive>(context, listen: false),
                      Provider.of<OAuth>(context, listen: false));
                  return DocumentsScreen(entity: data);
                }),
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
            Iterable<PDFDocument>? extra =
                state.extra as Iterable<PDFDocument>?;
            if (extra == null) {
              return const Placeholder();
            } else {
              return CompareScreen(documents: extra);
            }
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
          ListenableProxyProvider<Google, OAuth>(
              update: (_, google, __) => OAuth(google)),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<DocumentSelectionProvider>(
              create: (_) => DocumentSelectionProvider()),
          ChangeNotifierProvider<DrawerProvider>(
              create: (_) => DrawerProvider())
        ],
        child: DynamicColorScheme(
          title: "LazyEXT",
          routerConfig: _router,
        ));
  }
}
