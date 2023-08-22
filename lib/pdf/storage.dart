import 'dart:io';

import 'package:jni/jni.dart';
import 'package:mupdf_android/mupdf_android.dart';
import 'package:uuid/uuid.dart';

typedef Path = List<String>;
typedef FilePath = Path;

abstract class Storage {
  Future<File> savePDF(Path path, PDFDocument pdf);
}

class FileStorage implements Storage {
  final String root;
  FileStorage(this.root);

  @override
  Future<File> savePDF(Path path, PDFDocument pdf) async {
    String dest = "$root/${path.join("/")}/${const Uuid().v4()}.pdf";
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
