import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:lazyext/app/theme.dart';
import 'package:provider/provider.dart';

class DynamicColorScheme extends StatelessWidget {
  final RouterConfig<Object> routerConfig;
  final String title;
  const DynamicColorScheme(
      {super.key, required this.routerConfig, required this.title});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
        builder: (ColorScheme? light, ColorScheme? dark) {
      return Consumer<ThemeProvider>(builder: (context, theme, _) {
        return FutureBuilder<bool>(
            future: theme.followSystem,
            builder: (context, systemSnapshot) {
              return FutureBuilder<bool>(
                  future: theme.dark,
                  builder: (context, darkSnapshot) {
                    return MaterialApp.router(
                      title: title,
                      theme: ThemeData(
                          useMaterial3: true,
                          colorScheme: ((systemSnapshot.data ?? true)
                              ? (MediaQuery.of(context).platformBrightness ==
                                      Brightness.dark
                                  ? dark
                                  : light)
                              : (darkSnapshot.data ?? true)
                                  ? dark
                                  : light)),
                      routerConfig: routerConfig,
                    );
                  });
            });
      });
    });
  }
}
