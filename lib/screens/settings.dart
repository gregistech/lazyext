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
        FutureBuilder<dynamic>(
            future: prefs.theme,
            builder: (context, snapshot) {
              return SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_rounded),
                  title: const Text("Dark theme"),
                  value: (snapshot.data ?? "dark") == "dark",
                  onChanged: (bool value) {
                    setState(() {
                      prefs.theme = value ? "dark" : "light";
                    });
                  });
            }),
        ListTile(
          leading: const Icon(Icons.storage_rounded),
          title: const Text("Storage root"),
          onTap: () async {
            prefs.storageRoot = await FilePicker.platform.getDirectoryPath();
          },
        ),
        ListTile(
          leading: const Icon(Icons.download_rounded),
          title: const Text("Courses to fetch in background"),
          onTap: () {
            context.push("/settings/monitor");
          },
        )
      ]),
    );
  }
}
