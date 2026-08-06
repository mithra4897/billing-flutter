import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class ActivityWatchSecretStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

final class FlutterActivityWatchSecretStorage
    implements ActivityWatchSecretStorage {
  const FlutterActivityWatchSecretStorage({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

final class ActivityWatchKeyStoreException implements Exception {
  const ActivityWatchKeyStoreException(this.message);

  final String message;

  @override
  String toString() => 'ActivityWatchKeyStoreException: $message';
}

final class ActivityWatchKeyMaterial {
  ActivityWatchKeyMaterial({
    required List<int> databaseKey,
    required List<int> payloadKey,
    required List<int> identifierHmacKey,
  }) : _databaseKey = _validatedCopy(databaseKey, 'database'),
       _payloadKey = _validatedCopy(payloadKey, 'payload'),
       _identifierHmacKey = _validatedCopy(
         identifierHmacKey,
         'identifier HMAC',
       );

  static const int keyLength = 32;

  final Uint8List _databaseKey;
  final Uint8List _payloadKey;
  final Uint8List _identifierHmacKey;
  bool _destroyed = false;

  Uint8List get databaseKey => _copyWhileActive(_databaseKey);

  Uint8List get payloadKey => _copyWhileActive(_payloadKey);

  Uint8List get identifierHmacKey => _copyWhileActive(_identifierHmacKey);

  void destroy() {
    if (_destroyed) {
      return;
    }
    _destroyed = true;
    _databaseKey.fillRange(0, _databaseKey.length, 0);
    _payloadKey.fillRange(0, _payloadKey.length, 0);
    _identifierHmacKey.fillRange(0, _identifierHmacKey.length, 0);
  }

  Uint8List _copyWhileActive(Uint8List value) {
    if (_destroyed) {
      throw StateError('Activity Watch key material has been destroyed.');
    }
    return Uint8List.fromList(value);
  }

  static Uint8List _validatedCopy(List<int> value, String label) {
    if (value.length != keyLength) {
      throw ArgumentError.value(
        value.length,
        label,
        'Activity Watch keys must contain exactly $keyLength bytes.',
      );
    }
    return Uint8List.fromList(value);
  }
}

final class ActivityWatchKeyStore {
  ActivityWatchKeyStore({
    ActivityWatchSecretStorage storage =
        const FlutterActivityWatchSecretStorage(),
    Random? secureRandom,
  }) : _storage = storage,
       _secureRandom = secureRandom ?? Random.secure();

  static const String _databaseKeyName =
      'billing.activity-watch.database-key.v1';
  static const String _payloadKeyName = 'billing.activity-watch.payload-key.v1';
  static const String _identifierKeyName =
      'billing.activity-watch.identifier-hmac-key.v1';

  final ActivityWatchSecretStorage _storage;
  final Random _secureRandom;

  Future<ActivityWatchKeyMaterial> loadOrCreate() async {
    return ActivityWatchKeyMaterial(
      databaseKey: await _loadOrCreateKey(_databaseKeyName),
      payloadKey: await _loadOrCreateKey(_payloadKeyName),
      identifierHmacKey: await _loadOrCreateKey(_identifierKeyName),
    );
  }

  Future<Uint8List> _loadOrCreateKey(String name) async {
    final storedValue = await _storage.read(name);
    if (storedValue != null) {
      return _decodeStoredKey(storedValue);
    }

    final key = Uint8List.fromList(
      List<int>.generate(
        ActivityWatchKeyMaterial.keyLength,
        (_) => _secureRandom.nextInt(256),
        growable: false,
      ),
    );
    final encoded = base64UrlEncode(key);
    await _storage.write(name, encoded);

    final persistedValue = await _storage.read(name);
    if (persistedValue != encoded) {
      key.fillRange(0, key.length, 0);
      throw const ActivityWatchKeyStoreException(
        'Secure storage did not persist Activity Watch key material.',
      );
    }
    return key;
  }

  Uint8List _decodeStoredKey(String value) {
    try {
      final decoded = base64Url.decode(value);
      if (decoded.length != ActivityWatchKeyMaterial.keyLength) {
        throw const FormatException('Unexpected key length.');
      }
      return Uint8List.fromList(decoded);
    } on FormatException {
      throw const ActivityWatchKeyStoreException(
        'Stored Activity Watch key material is invalid.',
      );
    }
  }
}
