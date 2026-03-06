import 'package:lpu_touch/services/lpu_crypto.dart';
import 'package:dio/dio.dart';
void main() async {
  final lpu = LpuCrypto();
  final dio = Dio();
  var encrypted = lpu.encryptPayload({
      "UserId": "12505327",
      "password": "Ashmit@2005",
      "Identity": "aphone",
      "DeviceId": "dummy-uuid-123",
      "PlayerId": "null"
  }, "milkyway", "post");
  final res = await dio.post("https://ums.lpu.in/umswebservice/umswebservice.svc/PVR", data: encrypted);
  if(res.data != null && res.data['PVRResult'] != null) {
      final decrypted = lpu.decryptPayload(res.data['PVRResult']);
      print(decrypted);
  }
}
