import 'dart:io';
void main() async {
  var client = HttpClient();
  client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
  try {
    var req = await client.getUrl(Uri.parse('https://ums.lpu.in/api/Student/GetProfile'));
    var res = await req.close();
    print('Dart IO Status Code: ${res.statusCode}');
  } catch (e) {
    print(e);
  }
}
