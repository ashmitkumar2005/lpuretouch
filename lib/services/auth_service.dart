import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'lpu_crypto.dart';

class AuthService {
  static const String _pvrUrl =
      'https://ums.lpu.in/umswebservice/umswebservice.svc/PVR';
  static const String _dexUrl =
      'https://ums.lpu.in/umswebservice/umswebservice.svc/GetDEx';
  static const String _profileUrl =
      'https://mobileapi.lpu.in/api/Student/GetProfile';

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

          // Build a base user object from PVR result
          final Map<String, dynamic> tempUser = {'RegNo': regNo, 'ExtractedName': regNo};
          for (var item in parsed) {
            if (item is Map<String, dynamic>) {
              item.forEach((key, value) {
                if (key != 'MenuText' && key != 'Url' && key != 'RouteName' && value != null && value.toString().isNotEmpty) {
                  tempUser[key] = value;
                }
              });
            }
          }

          await _storage.write(key: 'lpu_token', value: token);
          await _storage.write(key: 'lpu_userId', value: userId);
          await _storage.write(key: 'lpu_user', value: jsonEncode(tempUser));
          await _storage.write(key: 'lpu_menus', value: pvrResult);

          // Immediately fetch real profile to get StudentName and all fields
          await fetchProfile();

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
  // Calls https://mobileapi.lpu.in/api/Student/GetProfile with Authorization header.
  // This mirrors the official UMS app's post-login profile call exactly.
  Future<void> fetchProfile() async {
    final token = await _storage.read(key: 'lpu_token');
    if (token == null) return;

    try {
      final resp = await _dio.get(
        _profileUrl,
        options: Options(headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        }),
      );

      if (resp.statusCode == 200 && resp.data != null) {
        Map<String, dynamic>? profileData;
        if (resp.data is List && (resp.data as List).isNotEmpty) {
          profileData = Map<String, dynamic>.from((resp.data as List)[0]);
        } else if (resp.data is Map) {
          profileData = Map<String, dynamic>.from(resp.data);
        }

        if (profileData != null) {
          final existingJson = await _storage.read(key: 'lpu_user');
          final Map<String, dynamic> existing =
              existingJson != null ? Map<String, dynamic>.from(jsonDecode(existingJson)) : {};
          existing.addAll(profileData);

          // Resolve the best display name from the profile response
          final name = profileData['StudentName'] ??
              profileData['Name'] ??
              profileData['FullName'] ??
              existing['RegNo'];
          existing['ExtractedName'] = name;

          await _storage.write(key: 'lpu_user', value: jsonEncode(existing));
        }
      }
    } catch (_) {
      // Silently fail — PVR-based fallback name is already stored
    }
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
