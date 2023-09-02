import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageRootScreen extends StatefulWidget {
  const StorageRootScreen({super.key});

  @override
  State<StorageRootScreen> createState() => _StorageRootScreenState();
}

class _StorageRootScreenState extends State<StorageRootScreen> {
  @override
  void initState() {
    FilePicker.platform.getDirectoryPath().then((String? path) {
      if (path != null) {
        SharedPreferences.getInstance().then((SharedPreferences prefs) {
          prefs.setString("storageRoot", path);
          context.pop();
        });
      } else {
        context.pop();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
