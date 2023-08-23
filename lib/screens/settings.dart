import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lazyext/preferences.dart';

import 'screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  dynamic prefs = Preferences();
  @override
  Widget build(BuildContext context) {
    return ScreenWidget(
      title: "Settings",
      child: ListView(children: [
        ListTile(
          title: const Text("Pick storage root"),
          onTap: () async {
            prefs.storageRoot = await FilePicker.platform.getDirectoryPath();
          },
        ),
        ListTile(
          title: const Text("Courses to monitor in background"),
          onTap: () {
            context.push("/settings/monitor");
          },
        )
      ]),
    );
  }
}
