import 'dart:io';
void main() async {
  var client = HttpClient();
  client.userAgent = "Mozilla/5.0 (Linux; Android 13; SM-S918B Build/TP1A.220624.014; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/114.0.5735.196 Mobile Safari/537.36";
  try {
    var req = await client.getUrl(Uri.parse('https://mobileapi.lpu.in/api/Student/GetProfile'));
    req.headers.set('X-Requested-With', 'com.lpu.lputouch');
    var res = await req.close();
    print('Dart IO Status Code: ${res.statusCode}');
  } catch (e) {
    print(e);
  }
}
