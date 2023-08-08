import 'package:flutter/material.dart';
import 'package:lazyext/screens/screen.dart';
import 'package:lazyext/widgets/compare.dart';

class CompareScreen extends StatelessWidget {
  final String path;
  const CompareScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ScreenWidget(
        title: "Compare",
        bottom: const TabBar(
          tabs: [Tab(icon: Text("Original")), Tab(icon: Text("Exercises"))],
        ),
        child: CompareView(path: path),
      ),
    );
  }
}
