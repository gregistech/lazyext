import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  Future<SharedPreferences> prefs = SharedPreferences.getInstance();

  @override
  noSuchMethod(Invocation invocation) async {
    if (invocation.isGetter) {
      return (await prefs).getString(invocation.memberName.toString());
    } else if (invocation.isSetter) {
      (await prefs).setString(
          invocation.memberName.toString().replaceAll("=", ""),
          invocation.positionalArguments.first);
    } else {
      super.noSuchMethod(invocation);
    }
  }
}
