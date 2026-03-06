import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:dio/dio.dart';

class LpuCrypto {
  static const String _base64Key = "m0rDSdPyzt+bo/BuTLgmXssN6TSzRPACdahgiCt5SLs=";
  static final enc.Key _key = enc.Key(base64Decode(_base64Key));

  static Map<String, String> encryptPayload({ required dynamic data, required String url, required String action }) {
    final payload = { 'url': url, 'action': action, 'data': data, 'guest': 'ums.lovely.university', 'guestcount': '20.87' };
    final plaintext = jsonEncode(payload);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return { 'v': iv.base64, 'd': encrypted.base64 };
  }
}

void main() async {
  final dio = Dio();
  var encrypted = LpuCrypto.encryptPayload(data: {
      "UserId": "12505327",
      "password": "Ashmit@2005",
      "Identity": "aphone",
      "DeviceId": "flutter-123",
      "PlayerId": "null"
  }, url: "milkyway", action: "post");
  
  try {
      final res = await dio.post("https://ums.lpu.in/umswebservice/umswebservice.svc/PVR", data: encrypted);
      if(res.data != null && res.data['PVRResult'] != null) {
          final pvrText = res.data['PVRResult'] as String;
          try {
             final decoded = jsonDecode(pvrText);
             if (decoded is List) {
                 final tk = decoded.firstWhere((x) => x['AccessToken'] != null, orElse: () => null);
                 if (tk != null) {
                     String tok = tk['AccessToken'];
                     print("Token: " + tok);
                     final parts = tok.split('.');
                     if(parts.length == 3) {
                        final payload = utf8.decode(base64Decode(parts[1] + '=='.substring(0, (4 - parts[1].length % 4) % 4)));
                        print("JWT Payload: " + payload);
                     } else {
                        print("Not a JWT token");
                     }
                 } else {
                    print(jsonEncode(decoded));
                 }
             }
          } catch(e) {
             print(pvrText);
          }
      }
  } catch(e) {
      print("Dio Error: $e");
  }
}
