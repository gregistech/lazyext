import 'package:flutter/material.dart';
import 'package:googleapis/classroom/v1.dart' hide Assignment;
import 'package:lazyext/screens/screen.dart';
import 'package:lazyext/widgets/assignment.dart';
import 'package:lazyext/widgets/compare.dart';

class CompareScreen extends StatelessWidget {
  final List<String> dest;
  final String path;
  const CompareScreen({super.key, required this.path, required this.dest});

  @override
  Widget build(BuildContext context) {
    const List<Tab> tabs = [
      Tab(icon: Text("Original")),
      Tab(icon: Text("Exercises")),
      Tab(icon: Text("Merged"))
    ];
    return DefaultTabController(
      length: tabs.length,
      child: ScreenWidget(
        title: "Compare",
        bottom: const TabBar(
          tabs: tabs,
        ),
        child: CompareView(dest: dest, path: path),
      ),
    );
  }
}
