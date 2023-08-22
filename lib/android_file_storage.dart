import 'package:file_picker/file_picker.dart';
import 'package:lazyext/pdf/storage.dart';
import 'package:lazyext/preferences.dart';

class AndroidFileStorage {
  dynamic prefs = Preferences();
  Future<FileStorage?>? storage;

  Future<FileStorage?> _rootToFileStorage(Future<dynamic> value) async {
    String? root = await value;
    if (root == null) {
      String? newRoot = await FilePicker.platform.getDirectoryPath();
      if (newRoot != null) {
        prefs.storageRoot = newRoot;
        return FileStorage(newRoot);
      }
    } else {
      return FileStorage(root);
    }
    return null;
  }

  AndroidFileStorage() {
    storage = _rootToFileStorage(prefs.storageRoot);
  }
}
