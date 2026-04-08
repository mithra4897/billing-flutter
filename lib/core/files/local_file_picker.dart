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
