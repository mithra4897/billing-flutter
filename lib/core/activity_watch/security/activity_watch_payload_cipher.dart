import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

final class ActivityWatchEncryptedPayload {
  ActivityWatchEncryptedPayload({
    required List<int> cipherText,
    required List<int> nonce,
    required List<int> authenticationTag,
  }) : cipherText = Uint8List.fromList(cipherText),
       nonce = Uint8List.fromList(nonce),
       authenticationTag = Uint8List.fromList(authenticationTag);

  final Uint8List cipherText;
  final Uint8List nonce;
  final Uint8List authenticationTag;
}

final class ActivityWatchPayloadCipher {
  ActivityWatchPayloadCipher({
    required List<int> payloadKey,
    required List<int> identifierHmacKey,
    AesGcm? cipher,
    Hmac? hmac,
  }) : _payloadKey = _validatedKey(payloadKey, 'payloadKey'),
       _identifierHmacKey = _validatedKey(
         identifierHmacKey,
         'identifierHmacKey',
       ),
       _cipher = cipher ?? AesGcm.with256bits(),
       _hmac = hmac ?? Hmac.sha256();

  final Uint8List _payloadKey;
  final Uint8List _identifierHmacKey;
  final AesGcm _cipher;
  final Hmac _hmac;
  bool _destroyed = false;

  Future<ActivityWatchEncryptedPayload> encrypt(
    List<int> clearText, {
    List<int> associatedData = const <int>[],
  }) async {
    _assertActive();
    final secretBox = await _cipher.encrypt(
      clearText,
      secretKey: SecretKey(_payloadKey),
      aad: associatedData,
    );
    return ActivityWatchEncryptedPayload(
      cipherText: secretBox.cipherText,
      nonce: secretBox.nonce,
      authenticationTag: secretBox.mac.bytes,
    );
  }

  Future<Uint8List> decrypt(
    ActivityWatchEncryptedPayload payload, {
    List<int> associatedData = const <int>[],
  }) async {
    _assertActive();
    final clearText = await _cipher.decrypt(
      SecretBox(
        payload.cipherText,
        nonce: payload.nonce,
        mac: Mac(payload.authenticationTag),
      ),
      secretKey: SecretKey(_payloadKey),
      aad: associatedData,
    );
    return Uint8List.fromList(clearText);
  }

  Future<String> hmacIdentifier(String value) async {
    _assertActive();
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, 'value', 'Identifier cannot be empty.');
    }
    final mac = await _hmac.calculateMac(
      utf8.encode(normalized),
      secretKey: SecretKey(_identifierHmacKey),
    );
    return _toHex(mac.bytes);
  }

  void destroy() {
    if (_destroyed) {
      return;
    }
    _destroyed = true;
    _payloadKey.fillRange(0, _payloadKey.length, 0);
    _identifierHmacKey.fillRange(0, _identifierHmacKey.length, 0);
  }

  void _assertActive() {
    if (_destroyed) {
      throw StateError('Activity Watch payload cipher has been destroyed.');
    }
  }

  static Uint8List _validatedKey(List<int> key, String label) {
    if (key.length != 32) {
      throw ArgumentError.value(
        key.length,
        label,
        'AES-256 and HMAC keys must contain exactly 32 bytes.',
      );
    }
    return Uint8List.fromList(key);
  }

  static String _toHex(List<int> bytes) =>
      bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
}
