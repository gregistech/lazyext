import 'package:file_picker/file_picker.dart';
import 'package:lazyext/pdf/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AndroidFileStorage {
  Future<FileStorage?> get storage async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? root = prefs.getString("storageRoot");
    if (root == null) {
      String? newRoot = await FilePicker.platform.getDirectoryPath();
      if (newRoot != null) {
        prefs.setString("storageRoot", newRoot);
        return FileStorage(newRoot);
      }
    } else {
      return FileStorage(root);
    }
    return null;
  }
}
