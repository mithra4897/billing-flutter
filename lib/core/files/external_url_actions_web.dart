// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

Future<bool> openExternalUrl(String url, {String? target}) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  html.window.open(trimmed, target ?? '_blank');
  return true;
}
