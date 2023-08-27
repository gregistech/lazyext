import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:lazyext/google/cached_teacher.dart';

class CachedTeacherProfilePicture extends StatelessWidget {
  final CachedTeacher? teacher;
  const CachedTeacherProfilePicture({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) {
    return ProfilePicture(
      name: teacher?.name ?? "",
      img: teacher?.img == null ? null : "https:${teacher?.img}",
      radius: 21,
      fontsize: 21,
    );
  }
}
