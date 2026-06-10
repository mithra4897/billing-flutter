import 'dart:typed_data';

import 'pdf_web_actions_stub.dart'
    if (dart.library.html) 'pdf_web_actions_web.dart' as impl;

Future<void> printPdfBytes(Uint8List bytes, {String? title}) {
  return impl.printPdfBytes(bytes, title: title);
}
