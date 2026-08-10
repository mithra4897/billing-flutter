import 'dart:convert';
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

  static Future<bool> applyEnrollment({
    required String deviceId,
    required String credential,
  }) async {
    final root = _defaultServiceRoot();
    if (root == null) return false;
    final configurationFile = File(
      path.join(root, 'activity-watch-agent.config.json'),
    );
    if (!await configurationFile.exists()) return false;

    final decoded = jsonDecode(await configurationFile.readAsString());
    if (decoded is! Map) {
      throw const FormatException('Activity Watch configuration is invalid.');
    }
    final configuration = Map<String, dynamic>.from(decoded);
    final syncValue = configuration['sync'];
    final collectionValue = configuration['collection'];
    if (syncValue is! Map || collectionValue is! Map) {
      throw const FormatException(
        'Activity Watch configuration is missing sync or collection settings.',
      );
    }
    final sync = Map<String, dynamic>.from(syncValue);
    final collection = Map<String, dynamic>.from(collectionValue);
    final credentialPath = sync['credential_file']?.toString();
    if (credentialPath == null || !path.isAbsolute(credentialPath)) {
      throw const FormatException(
        'Activity Watch credential_file must be an absolute path.',
      );
    }

    final credentialFile = File(credentialPath);
    await credentialFile.parent.create(recursive: true);
    final temporaryCredential = File('$credentialPath.tmp');
    await temporaryCredential.writeAsString(credential, flush: true);
    if (!Platform.isWindows) {
      final chmod = await Process.run('chmod', <String>[
        '600',
        temporaryCredential.path,
      ], runInShell: false);
      if (chmod.exitCode != 0) {
        await temporaryCredential.delete();
        throw StateError('Could not protect the Activity Watch credential.');
      }
    }
    await _replaceFile(temporaryCredential, credentialFile);

    sync['enabled'] = true;
    sync['device_id'] = deviceId;
    collection['disabled'] = false;
    configuration['sync'] = sync;
    configuration['collection'] = collection;
    final temporaryConfiguration = File('${configurationFile.path}.tmp');
    await temporaryConfiguration.writeAsString(
      const JsonEncoder.withIndent('  ').convert(configuration),
      flush: true,
    );
    await _replaceFile(temporaryConfiguration, configurationFile);

    final executableName = Platform.isWindows
        ? 'activity-watch-agent.exe'
        : 'activity-watch-agent';
    final executablePath = path.join(root, executableName);
    if (await File(executablePath).exists()) {
      await configure(
        executablePath: executablePath,
        configurationPath: configurationFile.path,
      );
    }
    return true;
  }

  static Future<void> signalLogoutIfConfigured() async {
    final values = await Future.wait<String?>(<Future<String?>>[
      _storage.read(key: _executablePathKey),
      _storage.read(key: _configurationPathKey),
    ]);
    var executablePath = values[0];
    var configurationPath = values[1];
    if (executablePath == null || configurationPath == null) {
      final root = _defaultServiceRoot();
      if (root == null) return;
      executablePath = path.join(
        root,
        Platform.isWindows
            ? 'activity-watch-agent.exe'
            : 'activity-watch-agent',
      );
      configurationPath = path.join(root, 'activity-watch-agent.config.json');
      if (!await File(executablePath).exists() ||
          !await File(configurationPath).exists()) {
        return;
      }
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

  static String? _defaultServiceRoot() {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      return home == null
          ? null
          : path.join(
              home,
              'Library',
              'Application Support',
              'BillingActivityWatch',
            );
    }
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      return localAppData == null
          ? null
          : path.join(localAppData, 'BillingActivityWatch');
    }
    if (Platform.isLinux) {
      final dataHome = Platform.environment['XDG_DATA_HOME'];
      if (dataHome != null && dataHome.isNotEmpty) {
        return path.join(dataHome, 'BillingActivityWatch');
      }
      final home = Platform.environment['HOME'];
      return home == null
          ? null
          : path.join(home, '.local', 'share', 'BillingActivityWatch');
    }
    return null;
  }

  static Future<void> _replaceFile(File temporary, File target) async {
    try {
      await temporary.rename(target.path);
    } on FileSystemException {
      await temporary.copy(target.path);
      await temporary.delete();
    }
  }
}
