import 'package:flutter/material.dart';
import 'package:lazyext/screens/screen.dart';
import 'package:lazyext/widgets/compare.dart';

class CompareScreen extends StatelessWidget {
  final String path;
  const CompareScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return ScreenWidget(title: "Compare", child: CompareView(path: path));
  }
}
