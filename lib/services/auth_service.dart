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
          final Map<String, dynamic> combinedUser = {};
          
          // Merge all attributes from all objects in the array to ensure we catch the Name
          for (var item in parsed) {
            if (item is Map<String, dynamic>) {
              item.forEach((key, value) {
                // Ignore menu routing items, keep user profile attributes
                if (key != 'MenuText' && key != 'Url' && key != 'RouteName' && value != null && value.toString().isNotEmpty) {
                  combinedUser[key] = value;
                }
              });
            }
          }

          // Fallback manual mappings if standard keys are missing
          combinedUser['RegNo'] = combinedUser['RegNo'] ?? tokenItem['RegNo'] ?? userId;
          
          // Heuristic to find the Name under various UMS keys
          final possibleName = combinedUser['Name'] ?? 
                               combinedUser['StudentName'] ?? 
                               combinedUser['ApplicantName'] ??
                               combinedUser['userName'] ??
                               combinedUser['FullName'] ??
                               combinedUser['FirstName'];
          
          if (possibleName != null) {
             combinedUser['ExtractedName'] = possibleName;
          } else {
             combinedUser['ExtractedName'] = userId;
          }

          await _storage.write(key: 'lpu_token', value: tokenItem['AccessToken']);
          await _storage.write(key: 'lpu_userId', value: userId);
          await _storage.write(key: 'lpu_user', value: jsonEncode(combinedUser));
          await _storage.write(key: 'lpu_menus', value: pvrResult);
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
