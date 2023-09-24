import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:googleapis/oauth2/v2.dart';
import 'package:intl/intl.dart';
import 'package:jni/jni.dart';
import 'package:lazyext/google/cached_teacher.dart';
import 'package:lazyext/google/classroom.dart';
import 'package:lazyext/google/drive.dart';
import 'package:lazyext/google/oauth.dart';
import 'package:mupdf_android/mupdf_android.dart' as mupdf;
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

extension CourseToDocumentEntity on Course {
  DocumentEntity toDocumentEntity(DocumentEntity parent, Classroom classroom,
          Drive drive, CachedTeacherProvider provider) =>
      ClassroomCourseDocumentEntity(parent, classroom, drive, provider, this);
}

extension on CourseWork {
  Assignment toAssignment() => Assignment.fromCourseWork(this);
}

extension on Announcement {
  Assignment toAssignment() => Assignment.fromAnnouncement(this);
}

extension AssignmentToDocumentEntity on Assignment {
  DocumentEntity toDocumentEntity(DocumentEntity parent, Classroom classroom,
          Drive drive, CachedTeacherProvider provider, Course course) =>
      ClassroomAssignmentDocumentEntity(
          parent, classroom, drive, provider, course, this);
}

extension MaterialToDocumentEntity on Material {
  Document? toDocument(DocumentEntity parent, Drive drive) {
    DriveFile? driveFile = this.driveFile?.driveFile;
    if (driveFile != null) {
      return DriveFileDocument(parent, drive, driveFile);
    } else {
      return null;
    }
  }
}

class Assignment implements Comparable<Assignment> {
  late final String id;
  late final String creatorId;
  late final String name;
  late final String text;
  late final List<Material> materials;
  late final DateTime creationTime;

  Assignment(this.id, this.name, this.text, this.materials, this.creationTime);
  Assignment.fromAnnouncement(Announcement announcement) {
    id = announcement.id ?? "";
    creatorId = announcement.creatorUserId ?? "";
    text = announcement.text ?? "";
    name = announcement.text?.substring(
            0,
            (announcement.text?.length ?? 0) > 21
                ? 20
                : (announcement.text?.length ?? 1) - 1) ??
        "";
    materials = announcement.materials ?? [];
    creationTime = DateTime.parse(announcement.creationTime ?? "");
  }
  Assignment.fromCourseWork(CourseWork courseWork) {
    id = courseWork.id ?? "";
    creatorId = courseWork.creatorUserId ?? "";
    text = courseWork.description ?? "";
    name = courseWork.title ?? "";
    materials = courseWork.materials ?? [];
    creationTime = DateTime.parse(courseWork.creationTime ?? "");
  }

  @override
  int compareTo(Assignment other) {
    return creationTime.compareTo(other.creationTime);
  }
}

class DriveFileDocument extends Document {
  DriveFileDocument(super.parent, this.drive, this.driveFile);
  final Drive drive;

  final DriveFile driveFile;
  late final Future<String?> _path = drive.downloadDriveFileAsPdf(driveFile);

  @override
  Future<String> get id async => driveFile.id ?? "Unknown";

  @override
  Future<mupdf.PDFDocument?> get document async {
    String? path = await _path;
    if (path != null) {
      return mupdf.Document.openDocument(path.toJString()).toPDFDocument();
    }
    return null;
  }

  @override
  Stream<DocumentEntity> get entities async* {}

  @override
  Future<String> get subtitle async => "";

  @override
  Future<String> get title async => driveFile.title ?? "";
}

class ClassroomRootDocumentEntity extends DocumentEntity {
  ClassroomRootDocumentEntity(
      super.parent, this.classroom, this.provider, this.drive, this.oauth);
  final Classroom classroom;
  final OAuth oauth;
  final Drive drive;
  final CachedTeacherProvider provider;

  late final Future<Userinfo?> _userinfo = oauth.getUserInfo();
  @override
  Future<String> get id async => (await _userinfo)?.id ?? "Unknown";

  @override
  Future<String> get title async => "Classroom";

  @override
  Stream<DocumentEntity> get entities async* {
    await for (Course course in classroom.stream(classroom.getCourses)) {
      DocumentEntity entity =
          course.toDocumentEntity(this, classroom, drive, provider);
      yield entity;
    }
  }

  @override
  Future<String> get subtitle async => "";

  /*@override
  Future<String> get subtitle async =>
      (await _userinfo)?.name ?? "Unknown user";*/
}

class ClassroomCourseDocumentEntity extends DocumentEntity {
  ClassroomCourseDocumentEntity(
      super.parent, this.classroom, this.drive, this.provider, this.course);
  final Classroom classroom;
  final Drive drive;
  final CachedTeacherProvider provider;

  final Course course;

  @override
  Future<String> get id async => course.id ?? "Unknown";

  @override
  Stream<DocumentEntity> get entities async* {
    await for (DocumentEntity entity in StreamGroup.merge([
      classroom
          .stream((({pageSize = 20, token}) => classroom.getCourseWork(course,
              pageSize: pageSize, token: token)))
          .asyncMap<DocumentEntity>((event) => event
              .toAssignment()
              .toDocumentEntity(this, classroom, drive, provider, course)),
      classroom
          .stream((({pageSize = 20, token}) => classroom
              .getAnnouncements(course, pageSize: pageSize, token: token)))
          .asyncMap<DocumentEntity>((event) => event
              .toAssignment()
              .toDocumentEntity(this, classroom, drive, provider, course))
    ])) {
      yield entity;
    }
  }

  @override
  Future<String> get subtitle async {
    String? id = course.id;
    String? owner = course.ownerId;
    if (id != null && owner != null) {
      return (await provider.getTeacher(id, owner))?.name ?? "Unknown teacher";
    } else {
      return "Unknown teacher";
    }
  }

  @override
  Future<String> get title async => course.name ?? "Unknown course";
}

class ClassroomAssignmentDocumentEntity extends DocumentEntity {
  ClassroomAssignmentDocumentEntity(super.parent, this.classroom, this.drive,
      this.provider, this.course, this.assignment);
  final Classroom classroom;
  final Drive drive;
  final Course course;
  final CachedTeacherProvider provider;
  final Assignment assignment;

  @override
  Future<String> get id async => assignment.id;

  @override
  Stream<DocumentEntity> get entities async* {
    for (Material material in assignment.materials) {
      Document? document = material.toDocument(this, drive);
      if (document != null) {
        yield document;
      }
    }
  }

  @override
  Future<String> get subtitle async {
    String? id = course.id;
    String? owner = course.ownerId;
    if (id != null && owner != null) {
      return (await provider.getTeacher(id, owner))?.name ?? "Unknown teacher";
    } else {
      return "Unknown teacher";
    }
  }

  @override
  Future<String> get title async => assignment.name;
}

extension FutureExtension<T> on Future<T> {
  bool isCompleted() {
    final completer = Completer<T>();
    then(completer.complete).catchError(completer.completeError);
    return completer.isCompleted;
  }
}

abstract class DocumentEntity {
  const DocumentEntity(this.parent);
  final DocumentEntity? parent;
  Future<String> get id async => const Uuid().v4();
  Future<String> get title;
  Future<String> get subtitle;
  Stream<DocumentEntity> get entities;

  Future<bool> isEqual(DocumentEntity other) async =>
      (await id) == (await other.id);
}

abstract class Document extends DocumentEntity {
  Document(super.parent);

  Future<mupdf.PDFDocument?> get document;

  @override
  Future<String> get title async =>
      (await document)?.title ?? "Unknown document";
}

class FileSystemDirectoryDocumentEntity extends FileSystemDocumentEntity {
  FileSystemDirectoryDocumentEntity(super.parent, super.entity);

  Directory get dir => entity as Directory;

  @override
  Stream<DocumentEntity> get entities async* {
    await for (FileSystemEntity entity in dir.list()) {
      if (entity is Directory) {
        yield FileSystemDirectoryDocumentEntity(this, entity);
      } else if (entity is File && p.extension(entity.path) == "pdf") {
        yield FileSystemDocument(this, entity);
      }
    }
  }
}

class FileSystemDocument extends FileSystemDocumentEntity implements Document {
  FileSystemDocument(super.parent, super.entity);

  File get file => entity as File;

  @override
  Future<mupdf.PDFDocument?> get document async =>
      mupdf.Document.openDocument(file.path.toJString()).toPDFDocument();

  @override
  Stream<DocumentEntity> get entities async* {}
}

abstract class FileSystemDocumentEntity extends DocumentEntity {
  FileSystemDocumentEntity(super.parent, this.entity);

  final FileSystemEntity entity;

  @override
  Future<String> get id async => entity.path;

  @override
  Future<String> get title async => p.basenameWithoutExtension(entity.path);

  @override
  Future<String> get subtitle async =>
      DateFormat.yMd().format((await entity.stat()).modified);
}
