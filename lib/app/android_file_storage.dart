import 'package:file_picker/file_picker.dart';
import 'package:lazyext/pdf/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AndroidFileStorage {
  late final Future<FileStorage?>? storage;

  Future<FileStorage?> _rootToFileStorage(String? root) async {
    if (root == null) {
      String? newRoot = await FilePicker.platform.getDirectoryPath();
      if (newRoot != null) {
        (await SharedPreferences.getInstance())
            .setString("storageRoot", newRoot);
        return FileStorage(newRoot);
      }
    } else {
      return FileStorage(root);
    }
    return null;
  }

  AndroidFileStorage() {
    SharedPreferences.getInstance().then((value) {
      storage = _rootToFileStorage(value.getString("storageRoot"));
    });
  }
}
