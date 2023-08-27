import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:http/http.dart';

import 'google.dart';

class Drive extends GoogleApi<DriveApi> with ChangeNotifier {
  @override
  final List<String> scopes = <String>[
    DriveApi.driveFileScope,
    DriveApi.driveReadonlyScope,
  ];

  Drive(Google google) : super(google, (Client client) => DriveApi(client));

  Future<File?> fileToGoogleDoc(File file) async {
    String? id = file.id;
    if (id != null) {
      return await getResponse(() async => (await api)
          ?.files
          .copy(File(mimeType: "application/vnd.google-apps.document"), id));
    } else {
      return null;
    }
  }

  Future<Media?> fileToPdf(File file) async {
    String? id = file.id;
    if (id != null) {
      return await getResponse(() async => (await api)?.files.export(
          id, "application/pdf",
          downloadOptions: DownloadOptions.fullMedia));
    } else {
      return null;
    }
  }

  Future<String?> downloadMedia(Media media, String path) async {
    io.IOSink sink = io.File(path).openWrite(mode: io.FileMode.write);
    await media.stream.pipe(sink);
    return path;
  }

  Future<File?> driveFileToFile(DriveFile driveFile) async {
    return await getResponse(() async {
      String? id = driveFile.id;
      if (id != null) {
        return (await (await api)?.files.get(id)) as File?;
      } else {
        return null;
      }
    });
  }
}
