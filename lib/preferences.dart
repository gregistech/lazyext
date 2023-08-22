import 'package:shared_preferences/shared_preferences.dart';

enum PreferenceKeys {
  storageRoot("storage_root");

  final String key;
  const PreferenceKeys(this.key);
}

class Preferences {
  Future<SharedPreferences> prefs = SharedPreferences.getInstance();

  Future<String?> get storageRoot async {
    return (await prefs).getString(PreferenceKeys.storageRoot.key);
  }

  set storageRoot(Future<String?> value) {
    value.then((String? value) => {
          if (value != null)
            {
              prefs.then((SharedPreferences prefs) =>
                  prefs.setString(PreferenceKeys.storageRoot.key, value))
            }
        });
  }
}
