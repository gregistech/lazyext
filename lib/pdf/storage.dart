import 'dart:io';

import 'package:jni/jni.dart';
import 'package:mupdf_android/mupdf_android.dart';
import 'package:uuid/uuid.dart';

typedef Path = List<String>;
typedef FilePath = Path;

extension ToString on Path {
  String _sanitizeDirectoryName(String input) {
    String sanitized = input.replaceAll(RegExp(r'[^\w\s-]'), '_');
    sanitized = sanitized.trim();
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    sanitized = sanitized.replaceAll(' ', '_');
    return sanitized;
  }

  String toSanitizedString() {
    Path sanitized = [];
    for (String step in this) {
      sanitized.add(_sanitizeDirectoryName(step));
    }
    return sanitized.join("/");
  }
}

abstract class Storage {
  Future<File> savePDF(Path path, PDFDocument pdf);
}

class FileStorage implements Storage {
  final String root;
  FileStorage(this.root);

  @override
  Future<File> savePDF(Path path, PDFDocument pdf) async {
    Directory dir = Directory("$root/${path.toSanitizedString()}");
    await dir.create(recursive: true);
    String name = const Uuid().v4();
    String dest = "${dir.path}/$name.pdf";
    pdf.save(dest.toJString(),
        "pretty,ascii,compress-images,compress-fonts".toJString());
    return File(dest);
  }
}

extension PathLists on FilePath {
  List<Path> _list<T extends FileSystemEntity>() {
    return Directory(join("/"))
        .listSync()
        .whereType<T>()
        .map((T entity) => entity.path.split("/"))
        .toList();
  }

  List<Path> get paths {
    return _list<Directory>();
  }

  List<Path> get pdfs {
    return _list<File>();
  }
}
