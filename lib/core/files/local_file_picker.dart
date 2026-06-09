import 'dart:typed_data';

import 'local_file_picker_stub.dart'
    if (dart.library.html) 'local_file_picker_web.dart'
    as picker;

class LocalPickedFile {
  const LocalPickedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

Future<LocalPickedFile?> pickSingleFile({String accept = '*/*'}) {
  return picker.pickSingleFile(accept: accept);
}

Future<bool> saveTextFile({
  required String suggestedName,
  required String text,
  String mimeType = 'application/json',
}) {
  return picker.saveTextFile(
    suggestedName: suggestedName,
    text: text,
    mimeType: mimeType,
  );
}

Future<bool> saveBytesFile({
  required String suggestedName,
  required Uint8List bytes,
  String mimeType = 'application/octet-stream',
}) {
  return picker.saveBytesFile(
    suggestedName: suggestedName,
    bytes: bytes,
    mimeType: mimeType,
  );
}
