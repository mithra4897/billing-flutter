import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../security/activity_watch_key_store.dart';
import '../security/activity_watch_payload_cipher.dart';
import 'activity_watch_database.dart';

abstract interface class ActivityWatchDatabasePathProvider {
  Future<String> databasePath();
}

final class PlatformActivityWatchDatabasePathProvider
    implements ActivityWatchDatabasePathProvider {
  const PlatformActivityWatchDatabasePathProvider();

  @override
  Future<String> databasePath() async {
    if (kIsWeb) {
      throw UnsupportedError('Activity Watch does not support Flutter web.');
    }
    final supportDirectory = await getApplicationSupportDirectory();
    final databaseDirectory = Directory(
      path.join(supportDirectory.path, 'activity_watch'),
    );
    await databaseDirectory.create(recursive: true);
    return path.join(databaseDirectory.path, 'activity_watch.db');
  }
}

final class ActivityWatchDatabaseContext {
  ActivityWatchDatabaseContext._({
    required this.database,
    required this.payloadCipher,
    required ActivityWatchKeyMaterial keyMaterial,
  }) : _keyMaterial = keyMaterial;

  final ActivityWatchDatabase database;
  final ActivityWatchPayloadCipher payloadCipher;
  final ActivityWatchKeyMaterial _keyMaterial;
  bool _closed = false;

  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    database.close();
    payloadCipher.destroy();
    _keyMaterial.destroy();
  }
}

final class ActivityWatchDatabaseManager {
  ActivityWatchDatabaseManager({
    ActivityWatchKeyStore? keyStore,
    ActivityWatchDatabasePathProvider pathProvider =
        const PlatformActivityWatchDatabasePathProvider(),
  }) : _keyStore = keyStore ?? ActivityWatchKeyStore(),
       _pathProvider = pathProvider;

  final ActivityWatchKeyStore _keyStore;
  final ActivityWatchDatabasePathProvider _pathProvider;

  Future<ActivityWatchDatabaseContext> open() async {
    if (kIsWeb) {
      throw UnsupportedError('Activity Watch does not support Flutter web.');
    }

    final keyMaterial = await _keyStore.loadOrCreate();
    ActivityWatchDatabase? database;
    try {
      final databasePath = await _pathProvider.databasePath();
      database = ActivityWatchDatabase.open(
        path: databasePath,
        key: keyMaterial.databaseKey,
      );
      final cipher = ActivityWatchPayloadCipher(
        payloadKey: keyMaterial.payloadKey,
        identifierHmacKey: keyMaterial.identifierHmacKey,
      );
      return ActivityWatchDatabaseContext._(
        database: database,
        payloadCipher: cipher,
        keyMaterial: keyMaterial,
      );
    } on Object {
      database?.close();
      keyMaterial.destroy();
      rethrow;
    }
  }
}
