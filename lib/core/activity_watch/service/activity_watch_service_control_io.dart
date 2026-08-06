import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;

final class ActivityWatchServiceControl {
  const ActivityWatchServiceControl._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _executablePathKey =
      'billing.activity-watch.service-executable-path.v1';
  static const String _configurationPathKey =
      'billing.activity-watch.service-configuration-path.v1';

  static Future<void> configure({
    required String executablePath,
    required String configurationPath,
  }) async {
    if (!path.isAbsolute(executablePath) ||
        !path.isAbsolute(configurationPath)) {
      throw ArgumentError('Activity Watch service paths must be absolute.');
    }
    if (!await File(executablePath).exists()) {
      throw ArgumentError.value(
        executablePath,
        'executablePath',
        'Activity Watch service executable does not exist.',
      );
    }
    if (!await File(configurationPath).exists()) {
      throw ArgumentError.value(
        configurationPath,
        'configurationPath',
        'Activity Watch service configuration does not exist.',
      );
    }
    await _storage.write(key: _executablePathKey, value: executablePath);
    await _storage.write(key: _configurationPathKey, value: configurationPath);
  }

  static Future<void> clearConfiguration() async {
    await Future.wait<void>(<Future<void>>[
      _storage.delete(key: _executablePathKey),
      _storage.delete(key: _configurationPathKey),
    ]);
  }

  static Future<void> signalLogoutIfConfigured() async {
    final values = await Future.wait<String?>(<Future<String?>>[
      _storage.read(key: _executablePathKey),
      _storage.read(key: _configurationPathKey),
    ]);
    final executablePath = values[0];
    final configurationPath = values[1];
    if (executablePath == null || configurationPath == null) {
      return;
    }
    if (!path.isAbsolute(executablePath) ||
        !path.isAbsolute(configurationPath)) {
      throw StateError('Stored Activity Watch service paths are invalid.');
    }

    final result = await Process.run(executablePath, <String>[
      'signal-logout',
      '--config',
      configurationPath,
    ], runInShell: false).timeout(const Duration(seconds: 3));
    if (result.exitCode != 0) {
      throw StateError(
        'Activity Watch service rejected the logout notification.',
      );
    }
  }
}
