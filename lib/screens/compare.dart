import 'package:flutter/material.dart';
import 'package:lazyext/screens/screen.dart';
import 'package:lazyext/widgets/compare.dart';

class CompareScreen extends StatelessWidget {
  final Iterable<String> path;
  const CompareScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    const List<Tab> tabs = [
      Tab(icon: Text("Original")),
      Tab(icon: Text("Merged"))
    ];
    return DefaultTabController(
        length: tabs.length, child: CompareScreenView(tabs: tabs, path: path));
  }
}

class CompareScreenView extends StatefulWidget {
  const CompareScreenView({
    super.key,
    required this.tabs,
    required this.path,
  });

  final List<Tab> tabs;
  final Iterable<String> path;

  @override
  State<CompareScreenView> createState() => _CompareScreenViewState();
}

class _CompareScreenViewState extends State<CompareScreenView> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    DefaultTabController.of(context).addListener(
        () => setState(() => index = DefaultTabController.of(context).index));
    return ScreenWidget(
      floatingActionButton: index == 1
          ? FloatingActionButton(
              onPressed: () {}, child: const Icon(Icons.merge_rounded))
          : null,
      title: "Compare",
      bottom: TabBar(
        tabs: widget.tabs,
      ),
      child: CompareView(paths: widget.path),
    );
  }
}
