import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class OriginalView extends StatelessWidget {
  final String path;
  const OriginalView({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return PDFView(
      filePath: path,
    );
  }
}

class ExtractedView extends StatelessWidget {
  const ExtractedView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class CompareView extends StatelessWidget {
  final String path;
  const CompareView({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: TabBarView(children: [
        OriginalView(
          path: path,
        ),
        const ExtractedView()
      ]),
    );
  }
}
