import 'package:flutter/material.dart';
import 'package:lazyext/app/preferences.dart';

class ThemeProvider with ChangeNotifier {
  final dynamic prefs = Preferences();

  set followSystem(Future<bool> value) {
    value.then((value) {
      prefs.followSystem = value.toString();
      notifyListeners();
    });
  }

  Future<bool> get followSystem async {
    return (await prefs.followSystem) == "true";
  }

  set dark(Future<bool> value) {
    value.then((value) {
      prefs.theme = value ? "dark" : "light";
      notifyListeners();
    });
  }

  Future<bool> get dark async {
    return await prefs.theme == "dark";
  }
}
