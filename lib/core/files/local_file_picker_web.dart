// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

import 'local_file_picker.dart';

Future<LocalPickedFile?> pickSingleFile({String accept = '*/*'}) async {
  final input = html.FileUploadInputElement()..accept = accept;
  final completer = Completer<LocalPickedFile?>();

  input.onChange.first.then((_) {
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) {
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.onError.first.then((_) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });
    reader.onLoad.first.then((_) {
      final result = reader.result;
      if (result is! ByteBuffer) {
        completer.complete(null);
        return;
      }

      completer.complete(
        LocalPickedFile(name: file.name, bytes: Uint8List.view(result)),
      );
    });
    reader.readAsArrayBuffer(file);
  });

  input.click();
  return completer.future;
}
