import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;

class LpuCrypto {
  static const String _base64Key =
      "m0rDSdPyzt+bo/BuTLgmXssN6TSzRPACdahgiCt5SLs=";

  static final enc.Key _key = enc.Key(base64Decode(_base64Key));

  /// Encrypts a payload and returns {v: ivBase64, d: cipherBase64}
  static Map<String, String> encryptPayload({
    required dynamic data,
    required String url,
    required String action,
  }) {
    final payload = {
      'url': url,
      'action': action,
      'data': data,
      'guest': 'ums.lovely.university',
      'guestcount': '20.87',
    };

    final plaintext = jsonEncode(payload);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return {
      'v': iv.base64,
      'd': encrypted.base64,
    };
  }
}
