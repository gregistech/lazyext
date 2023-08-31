import 'package:flutter/material.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:lazyext/google/classroom.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CachedTeacher {
  late String courseId;
  late String id;
  late String name;
  late String img;

  CachedTeacher(this.courseId, this.id, this.name, this.img);
  CachedTeacher.fromString(String entry) {
    List<String> data = entry.split(":");
    if (data.length == 4) {
      courseId = data[0];
      id = data[1];
      name = data[2];
      img = data[3];
    } else {
      courseId = "";
      id = "";
      name = "";
      img = "";
    }
  }
  CachedTeacher.fromTeacher(Teacher teacher) {
    courseId = teacher.courseId ?? "";
    id = teacher.userId ?? "";
    name = teacher.profile?.name?.fullName ?? "";
    img = teacher.profile?.photoUrl ?? "";
  }

  @override
  String toString() {
    return "$courseId:$id:$name:$img";
  }
}

class CachedTeacherProvider with ChangeNotifier {
  final Classroom _classroom;

  CachedTeacherProvider(this._classroom);

  Future<void> _storeTeacher(CachedTeacher teacher) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
        "teachers", "${prefs.getString("teachers")},${teacher.toString()}");
    changed = true;
  }

  bool changed = true;
  String? _teacherStore;
  Future<CachedTeacher?> getTeacher(String courseId, String id) async {
    if (changed) {
      _teacherStore =
          (await SharedPreferences.getInstance()).getString("teachers");
      changed = false;
    }
    String? teacherStore = _teacherStore;
    if (teacherStore != null) {
      List<String> teacherEntries = teacherStore.split(",");
      for (CachedTeacher teacher
          in teacherEntries.map((e) => CachedTeacher.fromString(e))) {
        if (teacher.id == id) {
          return teacher;
        }
      }
    }
    Teacher? teacher;
    try {
      teacher = await _classroom.getTeacher(courseId, id);
    } catch (_) {
      return null;
    }
    if (teacher != null) {
      CachedTeacher cached = CachedTeacher.fromTeacher(teacher);
      await _storeTeacher(cached);
      return cached;
    }
    return null;
  }
}
