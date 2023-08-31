import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  Future<bool> setFollowSystem(bool value) async {
    (await SharedPreferences.getInstance()).setBool("followSystem", value);
    notifyListeners();
    return value;
  }

  Future<bool> get followSystem async {
    return (await SharedPreferences.getInstance()).getBool("followSystem") ??
        true;
  }

  Future<bool> setDark(bool value) async {
    (await SharedPreferences.getInstance()).setBool("dark", value);
    notifyListeners();
    return value;
  }

  Future<bool> get dark async {
    return (await SharedPreferences.getInstance()).getBool("dark") ?? true;
  }
}
