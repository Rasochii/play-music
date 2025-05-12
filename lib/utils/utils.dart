import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/audio_model.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

Future<String?> pickFolder() async {
  if (await Permission.manageExternalStorage.request().isGranted) {
    // OK
  } else {
    openAppSettings();
  }
  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
  return selectedDirectory;
}

Future<List<Audio>> convertMetadata(List<FileSystemEntity> files) async {
  List<Audio> list = [];

  for (var file in files) {
    try {
      final metadata = await MetadataRetriever.fromFile(file as File);
      list.add(
        Audio(
          path: file.path,
          name: metadata.trackName ?? file.path.split('/').last,
          artist: metadata.authorName ?? 'Artista desconhecido',
          duration: metadata.trackDuration != null
              ? Duration(milliseconds: metadata.trackDuration!)
              : Duration.zero,
        ),
      );
    } catch (e) {
      // Ignora arquivos com erro
    }
  }

  return list;
}
