import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'lpu_crypto.dart';

class AuthService {
  static const String _pvrUrl =
      'https://ums.lpu.in/umswebservice/umswebservice.svc/PVR';
  static const String _dexUrl =
      'https://ums.lpu.in/umswebservice/umswebservice.svc/GetDEx';
  static const String _createTokenUrl =
      'https://mobileapi.lpu.in/security/createToken';
  static const String _profileQrUrl =
      'https://mobileapi.lpu.in/api/Student/GetProfile';

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ── Login ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String userId, String password) async {
    final deviceId = 'flutter-${DateTime.now().millisecondsSinceEpoch}';
    final loginData = {
      'UserId': userId,
      'password': password,
      'Identity': 'aphone',
      'DeviceId': deviceId,
      'PlayerId': 'null',
    };

    final encrypted =
        LpuCrypto.encryptPayload(data: loginData, url: 'milkyway', action: 'post');

    final response = await _dio.post(_pvrUrl, data: encrypted);

    if (response.statusCode == 200 && response.data != null) {
      final pvrResult = response.data['PVRResult'];
      if (pvrResult != null) {
        final List<dynamic> parsed = jsonDecode(pvrResult);
        final tokenItem = parsed.firstWhere(
          (e) => e['AccessToken'] != null && e['AccessToken'].toString().isNotEmpty,
          orElse: () => null,
        );
        if (tokenItem != null) {
          final token = tokenItem['AccessToken'].toString();
          final regNo = (tokenItem['RegNo'] ?? userId).toString();

          // Build a temporary user from PVR result immediately
          final Map<String, dynamic> tempUser = {
            'RegNo': regNo,
          };
          for (var item in parsed) {
            if (item is Map<String, dynamic>) {
              item.forEach((key, value) {
                if (key != 'MenuText' && key != 'Url' && key != 'RouteName' && value != null && value.toString().isNotEmpty) {
                  tempUser[key] = value;
                }
              });
            }
          }
          final possibleName = tempUser['Name'] ??
                               tempUser['StudentName'] ??
                               tempUser['ApplicantName'] ??
                               tempUser['userName'] ??
                               tempUser['FullName'] ??
                               tempUser['FirstName'];
          tempUser['ExtractedName'] = possibleName ?? regNo;

          await _storage.write(key: 'lpu_token', value: token);
          await _storage.write(key: 'lpu_userId', value: userId);
          await _storage.write(key: 'lpu_password', value: password);
          await _storage.write(key: 'lpu_deviceId', value: deviceId);
          await _storage.write(key: 'lpu_user', value: jsonEncode(tempUser));
          await _storage.write(key: 'lpu_menus', value: pvrResult);

          // Fire off a background profile fetch to populate real name
          fetchProfile().catchError((e) {
            print("Login fetchProfile Error: $e");
          });

          return {'success': true, 'data': parsed};
        } else {
          final msg = parsed.isNotEmpty
              ? (parsed[0]['Message'] ?? parsed[0]['MenuText'] ?? 'Login failed')
              : 'Login failed';
          return {'success': false, 'error': msg.toString().trim()};
        }
      }
    }
    return {'success': false, 'error': 'Server error'};
  }

  // ── Fetch Full Student Profile ────────────────────────────────────────────
  // Uses the native StudentBasicInfoForService endpoint on umswebservice.svc 
  // to completely bypass the Cloudflare Bot Protection on mobileapi.lpu.in.
  Future<void> fetchProfile() async {
    final token = await _storage.read(key: 'lpu_token');
    final userId = await _storage.read(key: 'lpu_userId');
    final deviceId = await _storage.read(key: 'lpu_deviceId') ?? 'flutter-123';

    if (token == null || userId == null) {
      print("[PROFILE] Missing credentials in storage. Aborting fetch.");
      return;
    }

    try {
      print("[PROFILE] Fetching StudentProfile from BasicInfo API...");
      final url = 'https://ums.lpu.in/umswebservice/umswebservice.svc/StudentBasicInfoForService/$userId/$token/$deviceId/null/null';
      final resp = await _dio.get(url);

      if (resp.statusCode == 200 && resp.data != null) {
        await _processProfileResult(resp.data);
      }
    } catch (e) {
      print("[PROFILE] BasicInfo API Error (Dio): $e.");
    }
  }

  Future<void> _processProfileResult(dynamic rawData) async {
    print("[PROFILE] RAW BASIC INFO RESPONSE: $rawData");
    Map<String, dynamic>? profileData;
    if (rawData is List && rawData.isNotEmpty) {
      profileData = rawData[0] as Map<String, dynamic>;
    } else if (rawData is Map) {
      profileData = rawData as Map<String, dynamic>;
    }

    if (profileData != null) {
      if (profileData['Error'] != null && profileData['Error'].toString().trim().isNotEmpty) {
        print("[PROFILE] Basic Info API returned an Error: ${profileData['Error']}");
        return;
      }

      final existingJson = await _storage.read(key: 'lpu_user');
      final Map<String, dynamic> existing = existingJson != null ? jsonDecode(existingJson) : {};
      existing.addAll(profileData);

      String? extractValidString(dynamic val) {
         if (val == null) return null;
         final s = val.toString().trim();
         return s.isEmpty ? null : s;
      }

      final name = extractValidString(profileData['StudentName']) ?? 
                   extractValidString(profileData['Name']) ?? 
                   extractValidString(profileData['FullName']) ?? 
                   existing['RegNo'];
                   
      existing['ExtractedName'] = name;
      await _storage.write(key: 'lpu_user', value: jsonEncode(existing));
      print("[PROFILE] Saved true student profile: $name");
    }
  }

  // ── Digital ID QR Drawing ───────────────────────────────────────────────
  
  Future<String?> fetchBearerToken() async {
    final userId = await _storage.read(key: 'lpu_userId');
    final password = await _storage.read(key: 'lpu_password');
    
    if (userId == null || password == null) {
      print("[BEARER_TOKEN] Missing credentials. Cannot generate token.");
      return null;
    }

    try {
      print("[BEARER_TOKEN] Fetching new mobile JWT token...");
      final response = await _dio.post(_createTokenUrl, data: {
        'userName': userId,
        'password': password,
      });

      if (response.statusCode == 200 && response.data != null) {
        final token = response.data['token'];
        if (token != null) {
          final bearerToken = 'Bearer $token';
          await _storage.write(key: 'lpu_bearer_token', value: bearerToken);
          print("[BEARER_TOKEN] Successfully obtained and cached mobile token.");
          return bearerToken;
        }
      }
    } catch (e) {
      print("[BEARER_TOKEN] Error: $e");
    }
    return null;
  }

  Future<String?> fetchStudentQR() async {
    try {
      // 1. Get Bearer Token (JWT)
      String? bearerToken = await _storage.read(key: 'lpu_bearer_token');
      if (bearerToken == null) {
        bearerToken = await fetchBearerToken();
      }

      if (bearerToken == null) {
        throw Exception("Failed to obtain Bearer token");
      }

      // 2. Fetch QR from mobileapi.lpu.in
      print("[HOSTEL_QR] Fetching QR from mobileapi.lpu.in...");
      final response = await _dio.get(
        _profileQrUrl,
        options: Options(headers: {
          'Authorization': bearerToken,
        }),
      );

      // Response format: item1: [{ data: "base64..." }]
      if (response.data != null && response.data['item1'] is List && (response.data['item1'] as List).isNotEmpty) {
        final qrData = response.data['item1'][0]['data']?.toString();
        print("[HOSTEL_QR] Successfully fetched QR data (length: ${qrData?.length ?? 0})");
        return qrData;
      }
    } catch (e) {
      print("[HOSTEL_QR] Error fetching student QR: $e");
      // If unauthorized, retry once after clearing cached bearer token
      if (e is DioException && e.response?.statusCode == 401) {
        print("[HOSTEL_QR] Token expired. Clearing cache.");
        await _storage.delete(key: 'lpu_bearer_token');
      }
    }
    return null;
  }

  // ── Generic UMS request (authenticated) ─────────────────────────────────

  Future<dynamic> umsRequest({
    required String endpoint,
    required String action,
    dynamic data,
  }) async {
    final token = await _storage.read(key: 'lpu_token');
    if (token == null) throw Exception('Not authenticated');

    final encrypted =
        LpuCrypto.encryptPayload(data: data ?? {}, url: endpoint, action: action);

    final response = await _dio.post(
      _dexUrl,
      data: encrypted,
      options: Options(headers: {'Token': token}),
    );
    return response.data;
  }

  // ── Auth State ────────────────────────────────────────────────────────────

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'lpu_token');
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getUser() async {
    final userJson = await _storage.read(key: 'lpu_user');
    if (userJson == null) return null;
    return jsonDecode(userJson);
  }

  Future<List<dynamic>> getMenus() async {
    final menusJson = await _storage.read(key: 'lpu_menus');
    if (menusJson == null) return [];
    return jsonDecode(menusJson);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
