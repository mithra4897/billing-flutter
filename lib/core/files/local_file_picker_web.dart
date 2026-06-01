// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

import 'local_file_picker.dart';

Future<LocalPickedFile?> pickSingleFile({String accept = '*/*'}) async {
  final input = html.FileUploadInputElement()..accept = accept;
  input.click();
  await input.onChange.first;

  final file = input.files?.isNotEmpty == true ? input.files!.first : null;
  if (file == null) {
    return null;
  }

  final reader = html.FileReader();
  final errorFuture = reader.onError.first.then((_) => null);
  final loadFuture = reader.onLoad.first.then((_) {
    final result = reader.result;
    if (result is! ByteBuffer) {
      return null;
    }
    return LocalPickedFile(name: file.name, bytes: Uint8List.view(result));
  });

  reader.readAsArrayBuffer(file);
  return await Future.any<LocalPickedFile?>([loadFuture, errorFuture]);
}

Future<bool> saveTextFile({
  required String suggestedName,
  required String text,
  String mimeType = 'application/json',
}) async {
  final bytes = Uint8List.fromList(text.codeUnits);
  final blob = html.Blob(<dynamic>[bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = suggestedName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return true;
}
