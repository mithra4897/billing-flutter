// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

Future<void> printPdfBytes(Uint8List bytes, {String? title}) async {
  final blob = html.Blob(<dynamic>[bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, title ?? '_blank');
  unawaited(
    Future<void>.delayed(const Duration(minutes: 2), () {
      html.Url.revokeObjectUrl(url);
    }),
  );
}
