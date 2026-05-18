import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'local_file_picker.dart';

Future<LocalPickedFile?> pickSingleFile({String accept = '*/*'}) async {
  FileType type = FileType.any;
  List<String>? allowedExtensions;

  final normalized = accept.trim().toLowerCase();
  if (normalized.contains('json') || normalized.contains('.json')) {
    type = FileType.custom;
    allowedExtensions = const ['json'];
  } else if (normalized.contains('image')) {
    type = FileType.image;
  }

  final result = await FilePicker.platform.pickFiles(
    type: type,
    allowedExtensions: allowedExtensions,
    withData: true,
  );
  if (result == null || result.files.isEmpty) {
    return null;
  }

  final file = result.files.first;
  final bytes = file.bytes;
  if (bytes == null) {
    return null;
  }

  return LocalPickedFile(name: file.name, bytes: bytes);
}

Future<bool> saveTextFile({
  required String suggestedName,
  required String text,
  String mimeType = 'application/json',
}) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Save file',
    fileName: suggestedName,
    type: FileType.custom,
    allowedExtensions: _extensionsForMimeType(mimeType, suggestedName),
  );
  if (path == null || path.trim().isEmpty) {
    return false;
  }

  final file = File(path);
  await file.writeAsString(text);
  return true;
}

List<String>? _extensionsForMimeType(String mimeType, String suggestedName) {
  final lowerName = suggestedName.toLowerCase();
  if (mimeType.contains('json') || lowerName.endsWith('.json')) {
    return const ['json'];
  }
  if (mimeType.contains('text')) {
    return const ['txt'];
  }
  return null;
}
