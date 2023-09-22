import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'google.dart';

class Drive extends GoogleApi<DriveApi> with ChangeNotifier {
  static const Set<String> staticScopes = {
    DriveApi.driveFileScope,
    DriveApi.driveReadonlyScope,
  };

  @override
  final Set<String> scopes = staticScopes;

  Drive(Google google) : super(google, (Client client) => DriveApi(client));

  Future<File?> fileToGoogleDoc(File file) async {
    String? id = file.id;
    if (id != null) {
      return await getResponse((DriveApi api) async => api.files
          .copy(File(mimeType: "application/vnd.google-apps.document"), id));
    } else {
      return null;
    }
  }

  Future<Media?> fileToPdf(File file) async {
    String? id = file.id;
    if (id != null) {
      return await getResponse((DriveApi api) async => api.files.export(
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

  Future<String?> downloadDriveFileAsPdf(DriveFile driveFile) async {
    File? file = await driveFileToFile(driveFile);
    if (file != null) {
      File? gdoc = await fileToGoogleDoc(file);
      if (gdoc != null) {
        Media? media = await fileToPdf(gdoc);
        if (media != null) {
          return downloadMedia(media,
              "${(await getTemporaryDirectory()).path}/${const Uuid().v4()}.pdf");
        }
      }
    }
    return null;
  }

  Future<File?> driveFileToFile(DriveFile driveFile) async {
    return await getResponse((DriveApi api) async {
      String? id = driveFile.id;
      if (id != null) {
        return (await api.files.get(id)) as File?;
      } else {
        return null;
      }
    });
  }
}
