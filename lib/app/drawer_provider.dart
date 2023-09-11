import 'package:flutter/foundation.dart';

class DrawerProvider extends ChangeNotifier {
  String _selected = "/courses";

  set selected(String value) {
    _selected = value;
    notifyListeners();
  }

  String get selected => _selected;
}
