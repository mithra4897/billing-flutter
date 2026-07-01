import 'dart:typed_data';

Future<void> printPdfBytes(Uint8List bytes, {String? title}) async {
  throw UnsupportedError('Web PDF actions are only available in browsers.');
}

Future<bool> openWebUrl(String url, {String? title}) async {
  return false;
}
