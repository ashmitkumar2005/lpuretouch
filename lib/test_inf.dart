import 'dart:convert';
import 'dart:io';

void main() async {
  var client = HttpClient();
  
  // These are fake/dummy tests but we can see what the server responds. Let's send a request and see what we get.
  // URL format: StudentBasicInfoForService/{userid}/{token}/{deviceid}/{lat}/{lng}
  final url = 'https://ums.lpu.in/umswebservice/umswebservice.svc/StudentBasicInfoForService/12505327/fake-token/flutter-123/null/null';
  
  try {
    var req = await client.getUrl(Uri.parse(url));
    var res = await req.close();
    print('Status: ${res.statusCode}');
    var body = await res.transform(utf8.decoder).join();
    print(body);
  } catch (e) {
    print(e);
  }
}
