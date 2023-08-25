import 'package:flutter/material.dart';
import 'package:lazyext/app/preferences.dart';

class ThemeProvider with ChangeNotifier {
  final dynamic prefs = Preferences();

  set followSystem(Future<bool> value) {
    value.then((value) => prefs)
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
