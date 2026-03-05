import 'dart:convert';
import 'lib/services/lpu_crypto.dart';
import 'package:dio/dio.dart';

void main() async {
  final _dio = Dio();
  final loginData = {
    'UserId': 'invalid',
    'password': 'password',
    'Identity': 'aphone',
    'DeviceId': 'flutter-123456',
    'PlayerId': 'null',
  };

  final encrypted = LpuCrypto.encryptPayload(data: loginData, url: 'milkyway', action: 'post');
  final response = await _dio.post('https://ums.lpu.in/umswebservice/umswebservice.svc/PVR', data: encrypted);
  
  if (response.data != null) {
      final pvrResult = response.data['PVRResult'];
      print('pvrResult string: $pvrResult');
      if (pvrResult != null) {
        final parsed = jsonDecode(pvrResult);
        print('parsed: $parsed');
        final tokenItem = parsed.firstWhere(
          (e) => e['AccessToken'] != null,
          orElse: () => null,
        );
        print('tokenItem: $tokenItem');
      }
  }
}
