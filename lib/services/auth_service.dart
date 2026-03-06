import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'lpu_crypto.dart';

class AuthService {
  static const String _pvrUrl =
      'https://ums.lpu.in/umswebservice/umswebservice.svc/PVR';
  static const String _dexUrl =
      'https://ums.lpu.in/umswebservice/umswebservice.svc/GetDEx';

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ── Login ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String userId, String password) async {
    final loginData = {
      'UserId': userId,
      'password': password,
      'Identity': 'aphone',
      'DeviceId': 'flutter-${DateTime.now().millisecondsSinceEpoch}',
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
  // Calls the encrypted GetDEx endpoint for Student/GetProfile, and if it fails or 404s,
  // structurally falls back to scanning the original PVR login response (`lpu_menus`) 
  // to extract the true student name.
  Future<void> fetchProfile() async {
    final token = await _storage.read(key: 'lpu_token');
    if (token == null) {
      print("[PROFILE] No token found in storage. Aborting fetch.");
      return;
    }

    try {
      print("[PROFILE] Fetching via secure GetDEx wrapper...");
      final respData = await umsRequest(
        endpoint: 'Student/GetProfile',
        action: 'get',
        data: {},
      );

      print("[PROFILE] API Success! Data type: ${respData.runtimeType}");
      
      if (respData != null) {
        dynamic parsedData = respData;
        if (respData is String) {
          try { parsedData = jsonDecode(respData); } catch(e) {}
        } else if (respData is Map && respData.containsKey('GetDExResult')) {
           final dexRes = respData['GetDExResult'];
           parsedData = (dexRes is String) ? jsonDecode(dexRes) : dexRes;
        }

        Map<String, dynamic>? profileData;
        if (parsedData is List && parsedData.isNotEmpty) {
          profileData = parsedData[0] as Map<String, dynamic>;
        } else if (parsedData is Map) {
          profileData = parsedData as Map<String, dynamic>;
        }

        if (profileData != null) {
          await _updateStoredUserName(profileData['StudentName'] ?? profileData['Name'] ?? profileData['FullName']);
          return; // Success, exit early
        }
      }
    } catch (e) {
      print("[PROFILE] Main API Error: $e. Falling back to PVR Cache...");
    }

    // --- FALLBACK: Extract name from the original PVR Response stored in lpu_menus ---
    try {
      final menusJson = await _storage.read(key: 'lpu_menus');
      if (menusJson != null) {
        final List<dynamic> pvrResult = jsonDecode(menusJson);
        for (var item in pvrResult) {
          if (item is Map) {
            final possibleName = item['Name'] ?? 
                                 item['StudentName'] ?? 
                                 item['ApplicantName'] ??
                                 item['FullName'] ??
                                 item['FirstName'];
            if (possibleName != null && possibleName.toString().isNotEmpty) {
              print("[PROFILE] Recovered name from PVR Cache: $possibleName");
              await _updateStoredUserName(possibleName.toString());
              return;
            }
          }
        }
      }
    } catch (e) {
      print("[PROFILE] Fallback Error: $e");
    }
  }

  Future<void> _updateStoredUserName(String? newName) async {
      if (newName == null) return;
      final existingJson = await _storage.read(key: 'lpu_user');
      final Map<String, dynamic> existing = existingJson != null ? jsonDecode(existingJson) : {};
      existing['ExtractedName'] = newName;
      await _storage.write(key: 'lpu_user', value: jsonEncode(existing));
      print("[PROFILE] Self-Healed and saved ExtractedName as $newName");
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
