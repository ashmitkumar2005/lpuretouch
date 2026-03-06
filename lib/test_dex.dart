import 'package:dio/dio.dart';
import 'package:lpu_touch/services/lpu_crypto.dart';
import 'dart:convert';
void main() async {
  final lpu = LpuCrypto.encryptPayload(data: {}, url: 'Student/GetProfile', action: 'get');
  var dio = Dio();
  try {
     var res = await dio.post('https://ums.lpu.in/umswebservice/umswebservice.svc/GetDEx', data: lpu, options: Options(headers: {'Token': 'fake-token'}));
     print("GetProfile on GetDEx returned: " + res.statusCode.toString());
     print(res.data);
  } catch (e) {
     print("Error: " + e.toString());
  }
}
