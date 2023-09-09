import 'package:flutter/material.dart' hide Material;
import 'package:go_router/go_router.dart';
import 'package:googleapis/classroom/v1.dart' hide Assignment;
import 'package:googleapis/drive/v3.dart' hide Drive;
import 'package:lazyext/google/drive.dart';
import 'package:lazyext/screens/screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../widgets/assignment.dart';

class AssignmentsScreen extends StatefulWidget {
  final Course course;
  const AssignmentsScreen({super.key, required this.course});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  List<Material> selected = [];

  Future<List<String?>> _downloadPdfs() async {
    List<Future<String?>> jobs = [];
    Drive drive = Provider.of<Drive>(context, listen: false);
    for (Material material in selected) {
      DriveFile? driveFile = material.driveFile?.driveFile;
      if (driveFile != null) {
        File? file = await drive.driveFileToFile(driveFile);
        if (file != null) {
          File? gdoc = await drive.fileToGoogleDoc(file);
          if (gdoc != null) {
            Media? pdf = await drive.fileToPdf(gdoc);
            if (pdf != null) {
              jobs.add(drive.downloadMedia(pdf,
                  "${(await getApplicationDocumentsDirectory()).path}/${const Uuid().v4()}.pdf"));
            }
          }
        }
      }
    }
    return jobs.wait;
  }

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return ScreenWidget(
      title: "Assignments",
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10),
          child: Visibility(
            visible: loading,
            child: const LinearProgressIndicator(),
          )),
      floatingActionButton: Visibility(
          visible: selected.isNotEmpty,
          child: FloatingActionButton.extended(
            label: const Text("Open"),
            icon: const Icon(Icons.file_open),
            onPressed: () async {
              setState(() => loading = true);
              await context.push("/compare",
                  extra: (await _downloadPdfs()).nonNulls.toList());
              setState(() => loading = false);
            },
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      child: AssignmentListView(
        course: widget.course,
        onSelectionChanged: (selection) => setState(() => selected = selection),
      ),
    );
  }
}
