import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'lpu_crypto.dart';
import 'cache_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class AuthService {
  static const String _pvrUrl =
      'https://ums.lpu.in/umswebservice/umswebservice.svc/PVR';
  static const String _dexUrl =
      'https://ums.lpu.in/umswebservice/umswebservice.svc/GetDEx';
  static const String _createTokenUrl =
      'https://mobileapi.lpu.in/security/createToken';
  static const String _profileQrUrl =
      'https://mobileapi.lpu.in/api/Student/GetProfile';

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal() {
    _setupInterceptors();
  }

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final CacheService _cache = CacheService();

  // ── Session Invalidation Handling ──────────────────────────────────────────

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) async {
        if (_isSessionExpired(response.data)) {
          print(
              '[AUTH_SERVICE] !!! SESSION EXPIRED DETECTED in response body !!!');
          print('[AUTH_SERVICE] Body was: ${response.data}');
          await forceLogout();
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: 'Session Expired',
            ),
          );
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          print('[AUTH_SERVICE] !!! SESSION EXPIRED DETECTED (401) !!!');
          await forceLogout();
        }
        return handler.next(e);
      },
    ));
  }

  bool _isSessionExpired(dynamic data) {
    if (data == null) return false;

    // LPU UMS often returns errors as: [{"Error": "Session Expired"}] or {"Error": "..."}
    // We explicitly check the content of fields named 'Error', 'Message', or 'msg'.

    bool checkValue(dynamic val) {
      if (val == null) return false;
      final s = val.toString().toLowerCase();
      return s.contains('session expired') ||
          s.contains('invalid token') ||
          s.contains('unauthorized') ||
          s.contains('your session has expired');
    }

    if (data is Map) {
      if (checkValue(data['Error']) ||
          checkValue(data['Message']) ||
          checkValue(data['msg'])) return true;
    } else if (data is List) {
      for (var item in data) {
        if (item is Map) {
          if (checkValue(item['Error']) ||
              checkValue(item['Message']) ||
              checkValue(item['msg'])) return true;
        }
      }
    }

    return false;
  }

  Future<void> forceLogout() async {
    await logout();
    // We'll use a static flag or callback to trigger GlobalLayout refresh
    _forceLogoutTrigger.value = true;
  }

  static final ValueNotifier<bool> _forceLogoutTrigger =
      ValueNotifier<bool>(false);
  static ValueListenable<bool> get onForceLogout => _forceLogoutTrigger;
  static void resetForceLogout() => _forceLogoutTrigger.value = false;

  final ValueNotifier<bool> _isLoggedInNotifier = ValueNotifier<bool>(false);
  ValueListenable<bool> get isLoggedInNotifier => _isLoggedInNotifier;

  bool get currentLoginState => _isLoggedInNotifier.value;

  void updateLoginState(bool loggedIn) {
    if (_isLoggedInNotifier.value != loggedIn) {
      _isLoggedInNotifier.value = loggedIn;
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String userId, String password) async {
    final deviceId = 'flutter-${DateTime.now().millisecondsSinceEpoch}';
    final loginData = {
      'UserId': userId,
      'password': password,
      'Identity': 'aphone',
      'DeviceId': deviceId,
      'PlayerId': 'null',
    };

    final encrypted = LpuCrypto.encryptPayload(
        data: loginData, url: 'milkyway', action: 'post');
    print('[AUTH_SERVICE] Sending login request to PVR...');
    final response = await _dio.post(_pvrUrl, data: encrypted);
    print('[AUTH_SERVICE] Response status: ${response.statusCode}');

    if (response.statusCode == 200 && response.data != null) {
      final pvrResult = response.data['PVRResult'];
      print(
          '[AUTH_SERVICE] PVRResult received (length: ${pvrResult?.toString().length})');
      if (pvrResult != null) {
        final List<dynamic> parsed = jsonDecode(pvrResult);
        print('[AUTH_SERVICE] PVRResult parsed. Item count: ${parsed.length}');

        final tokenItem = parsed.firstWhere(
          (e) =>
              e['AccessToken'] != null &&
              e['AccessToken'].toString().isNotEmpty,
          orElse: () => null,
        );

        if (tokenItem == null) {
          print('[AUTH_SERVICE] AccessToken NOT FOUND in parsed PVRResult.');
          // Log keys of first item for debugging
          if (parsed.isNotEmpty) {
            print('[AUTH_SERVICE] First item keys: ${parsed[0].keys}');
          }
        } else {
          print('[AUTH_SERVICE] AccessToken found.');
        }
        if (tokenItem != null) {
          final token = tokenItem['AccessToken'].toString();
          final regNo = (tokenItem['RegNo'] ?? userId).toString();

          final Map<String, dynamic> tempUser = {'RegNo': regNo};
          for (var item in parsed) {
            if (item is Map<String, dynamic>) {
              item.forEach((key, value) {
                if (key != 'MenuText' &&
                    key != 'Url' &&
                    key != 'RouteName' &&
                    value != null &&
                    value.toString().isNotEmpty) {
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

          // Clear any stale profile cache from a previous session
          await _cache.invalidate('profile');

          // Fire background profile fetch to update name immediately
          fetchProfile()
              .catchError((e) => print('Login fetchProfile Error: $e'));

          updateLoginState(true);
          return {'success': true, 'data': parsed};
        } else {
          final msg = parsed.isNotEmpty
              ? (parsed[0]['Message'] ??
                  parsed[0]['MenuText'] ??
                  'Login failed')
              : 'Login failed';
          return {'success': false, 'error': msg.toString().trim()};
        }
      }
    }
    return {'success': false, 'error': 'Server error'};
  }

  // ── Fetch Full Student Profile ─────────────────────────────────────────────
  // Uses StudentBasicInfoForService to bypass Cloudflare on mobileapi.lpu.in.

  Future<void> fetchProfile({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      // ── Fresh cache hit: serve immediately, skip network ──────────────────
      final cached = await _cache.get('profile');
      if (cached != null) {
        print('[PROFILE] Serving from cache (fresh).');
        await _mergeToSecureStorage(cached as Map<String, dynamic>);
        return;
      }
      // ── Stale-while-revalidate: serve old data instantly, refresh below ───
      final stale = await _cache.getStale('profile');
      if (stale != null) {
        print('[PROFILE] Serving stale cache, refreshing in background...');
        await _mergeToSecureStorage(stale as Map<String, dynamic>);
        // fall through to fetch fresh data
      }
    }

    final token = await _storage.read(key: 'lpu_token');
    final userId = await _storage.read(key: 'lpu_userId');
    final deviceId = await _storage.read(key: 'lpu_deviceId') ?? 'flutter-123';

    if (token == null || userId == null) {
      print('[PROFILE] Missing credentials. Aborting fetch.');
      return;
    }

    print('[PROFILE] Fetching StudentProfile from BasicInfo API...');
    final url =
        'https://ums.lpu.in/umswebservice/umswebservice.svc/StudentBasicInfoForService'
        '/$userId/$token/$deviceId/null/null';
    final resp = await _dio.get(url);
    if (resp.statusCode == 200 && resp.data != null) {
      await _processProfileResult(resp.data);
    }
  }

  Future<void> _mergeToSecureStorage(Map<String, dynamic> data) async {
    final existingJson = await _storage.read(key: 'lpu_user');
    final existing = existingJson != null
        ? jsonDecode(existingJson) as Map<String, dynamic>
        : <String, dynamic>{};
    existing.addAll(data);
    await _storage.write(key: 'lpu_user', value: jsonEncode(existing));
  }

  Future<void> _processProfileResult(dynamic rawData) async {
    Map<String, dynamic>? profileData;
    if (rawData is List && rawData.isNotEmpty) {
      profileData = rawData[0] as Map<String, dynamic>;
    } else if (rawData is Map) {
      profileData = rawData as Map<String, dynamic>;
    }
    if (profileData == null) return;

    if (profileData['Error'] != null &&
        profileData['Error'].toString().trim().isNotEmpty) {
      print('[PROFILE] API returned Error: ${profileData['Error']}');
      return;
    }

    final existingJson = await _storage.read(key: 'lpu_user');
    final Map<String, dynamic> existing =
        existingJson != null ? jsonDecode(existingJson) : {};
    existing.addAll(profileData);

    String? _str(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    final name = _str(profileData['StudentName']) ??
        _str(profileData['Name']) ??
        _str(profileData['FullName']) ??
        existing['RegNo'];

    existing['ExtractedName'] = name;
    await _storage.write(key: 'lpu_user', value: jsonEncode(existing));

    // Cache the fresh data (1h TTL)
    await _cache.set('profile', profileData, ttl: CacheService.profileTTL);
    print('[PROFILE] Saved: $name (cached 1h)');
  }

  // ── Fetch Timetable ───────────────────────────────────────────────────────

  Future<List<dynamic>?> fetchTimetable() async {
    final token = await _storage.read(key: 'lpu_token');
    final userId = await _storage.read(key: 'lpu_userId');
    final deviceId = await _storage.read(key: 'lpu_deviceId') ?? 'flutter-123';

    if (token == null || userId == null) {
      print('[TIMETABLE] Missing credentials. Aborting fetch.');
      return null;
    }

    print('[TIMETABLE] Fetching from UMS API...');
    final url =
        'https://ums.lpu.in/umswebservice/umswebservice.svc/StudentTimeTableForService/$userId/$token/$deviceId';
    final resp = await _dio.get(url);
    if (resp.statusCode == 200 && resp.data != null) {
      if (resp.data is List) {
        return resp.data as List<dynamic>;
      }
    }
    return null;
  }

  // ── Fetch Announcements ───────────────────────────────────────────────────

  // ── Fetch Announcements ───────────────────────────────────────────────────

  Future<List<dynamic>?> fetchAnnouncements() async {
    final token = await _storage.read(key: 'lpu_token');
    final userId = await _storage.read(key: 'lpu_userId');
    final deviceId = await _storage.read(key: 'lpu_deviceId') ?? 'flutter-123';

    if (token == null || userId == null) return null;

    try {
      print(
          '[ANNOUNCEMENTS] Fetching from UMS API: GetAnnouncementsForServiceNew');
      // Exact endpoint extracted from original app: GetAnnouncementsForServiceNew/{userId}/{token}/{deviceId}/S
      final url =
          'https://ums.lpu.in/umswebservice/umswebservice.svc/GetAnnouncementsForServiceNew/$userId/$token/$deviceId/S';
      final resp = await _dio.get(url);

      if (resp.statusCode == 200 && resp.data != null) {
        if (resp.data is List &&
            resp.data.isNotEmpty &&
            !(resp.data.first is Map && resp.data.first.containsKey('Error'))) {
          print('[ANNOUNCEMENTS] Fetch Success: ${resp.data.length} items');
          print('[ANNOUNCEMENTS] Sample item keys: ${resp.data.first.keys}');
          print('[ANNOUNCEMENTS] Sample item: ${resp.data.first}');
          return resp.data as List<dynamic>;
        }
      }
    } catch (e) {
      print('[ANNOUNCEMENTS] Fetch Error: $e');
    }

    return null; // Return null on failure instead of mock data now that we have the real API
  }

  // ── Fetch My Messages ─────────────────────────────────────────────────────

  Future<List<dynamic>?> fetchMyMessages() async {
    const cacheKey = 'my_messages';
    // 1. Serve from Hive if fresh
    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      return List<dynamic>.from(cached);
    }

    final token = await _storage.read(key: 'lpu_token');
    final userId = await _storage.read(key: 'lpu_userId');
    final deviceId = await _storage.read(key: 'lpu_deviceId') ?? 'flutter-123';
    final userType = await _storage.read(key: 'lpu_userType'); // Optional: 'Student' or 'Employee'

    if (token == null || userId == null) return null;

    try {
      final endpoint = userType == 'Employee'
          ? 'EmployeeMyMessagesForService'
          : 'StudentMyMessagesForService';

      final url =
          'https://ums.lpu.in/umswebservice/umswebservice.svc/$endpoint/$userId/$token/$deviceId';
      final resp = await _dio.get(url);

      if (resp.statusCode == 200 && resp.data != null) {
        final parsedData =
            resp.data is String ? jsonDecode(resp.data) : resp.data;

        if (parsedData is List && parsedData.isNotEmpty) {
          final firstItem = parsedData.first as Map<String, dynamic>;
          // The API sometimes returns an object with a real Error message,
          // but valid messages also contain 'Error': ''
          final hasError = firstItem.containsKey('Error') && 
                           firstItem['Error'] != null && 
                           firstItem['Error'].toString().trim().isNotEmpty;

          if (!hasError) {
            // 2. Write to Hive
            await _cache.set(cacheKey, parsedData, ttl: CacheService.announcementsTTL);
            return List<dynamic>.from(parsedData);
          }
        }
      }
    } catch (e) {
      print('API Error: $e');

      // 3. On network error, try stale cache
      final stale = await _cache.getStale(cacheKey);
      if (stale != null) {
        return List<dynamic>.from(stale as List);
      }
    }
    return null;
  }

  // ── Fetch Announcement Details ──────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchAnnouncementDetails(
      String aId, String tbl) async {
    final bearerToken = await fetchBearerToken();
    if (bearerToken == null) return null;

    try {
      print('[ANNOUNCEMENTS] Fetching details for AId: $aId, tbl: $tbl');
      // Mobile API endpoint for details: Announcement/GetAnnouncementDetails?AId={c}&tbl={m}
      final url =
          'https://mobileapi.lpu.in/api/Announcement/GetAnnouncementDetails?AId=$aId&tbl=$tbl';
      final resp = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearerToken',
          },
        ),
      );

      if (resp.statusCode == 200 && resp.data != null) {
        return resp.data as Map<String, dynamic>;
      }
    } catch (e) {
      print('[ANNOUNCEMENTS] Fetch Details Error: $e');
    }
    return null;
  }

  // ── Bearer Token (JWT for mobileapi) ──────────────────────────────────────

  Future<String?> fetchBearerToken() async {
    // Cache hit (55min TTL — JWT expires at 60min)
    final cachedToken = await _cache.get('bearer_token');
    if (cachedToken != null) {
      print('[BEARER_TOKEN] Serving from cache.');
      final t = cachedToken.toString();
      await _storage.write(key: 'lpu_bearer_token', value: t);
      return t;
    }

    final userId = await _storage.read(key: 'lpu_userId');
    final password = await _storage.read(key: 'lpu_password');
    if (userId == null || password == null) {
      print('[BEARER_TOKEN] Missing credentials.');
      return null;
    }

    try {
      print('[BEARER_TOKEN] Fetching new JWT...');
      final response = await _dio.post(_createTokenUrl,
          data: {'userName': userId, 'password': password});
      if (response.statusCode == 200 && response.data != null) {
        final token = response.data['token'];
        if (token != null) {
          final bearerToken = 'Bearer $token';
          await _storage.write(key: 'lpu_bearer_token', value: bearerToken);
          await _cache.set('bearer_token', bearerToken,
              ttl: CacheService.bearerTokenTTL);
          print('[BEARER_TOKEN] Obtained and cached (55min).');
          return bearerToken;
        }
      }
    } catch (e) {
      print('[BEARER_TOKEN] Error: $e');
    }
    return null;
  }

  // ── Student QR ────────────────────────────────────────────────────────────

  Future<String?> fetchStudentQR() async {
    // Cache hit (10min TTL)
    final cachedQR = await _cache.get('student_qr');
    if (cachedQR != null) {
      print('[HOSTEL_QR] Serving from cache.');
      return cachedQR.toString();
    }

    // Resolve bearer token (cache → storage → fetch)
    String? bearerToken = await _cache.get('bearer_token');
    bearerToken ??= await _storage.read(key: 'lpu_bearer_token');
    bearerToken ??= await fetchBearerToken();
    if (bearerToken == null) throw Exception('Failed to obtain Bearer token');

    print('[HOSTEL_QR] Fetching QR from mobileapi.lpu.in...');
    final response = await _dio.get(
      _profileQrUrl,
      options: Options(headers: {'Authorization': bearerToken}),
    );

    if (response.data != null &&
        response.data['item1'] is List &&
        (response.data['item1'] as List).isNotEmpty) {
      final qrData = response.data['item1'][0]['data']?.toString();
      print('[HOSTEL_QR] Fetched QR (length: ${qrData?.length ?? 0})');
      if (qrData != null) {
        await _cache.set('student_qr', qrData, ttl: CacheService.qrDataTTL);
      }
      return qrData;
    }
    return null;
  }

  // ── Generic UMS request ───────────────────────────────────────────────────

  Future<dynamic> umsRequest({
    required String endpoint,
    required String action,
    dynamic data,
  }) async {
    final token = await _storage.read(key: 'lpu_token');
    if (token == null) throw Exception('Not authenticated');
    final encrypted = LpuCrypto.encryptPayload(
        data: data ?? {}, url: endpoint, action: action);
    final response = await _dio.post(
      _dexUrl,
      data: encrypted,
      options: Options(headers: {'Token': token}),
    );
    return response.data;
  }

  // ── Auth State ─────────────────────────────────────────────────────────────

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'lpu_token');
    return token != null && token.isNotEmpty;
  }

  /// Proactively verifies if the current session is still valid by making
  /// a lightweight API call that would trigger the SessionInterceptor on failure.
  Future<bool> validateSession() async {
    final token = await _storage.read(key: 'lpu_token');
    if (token == null || token.isEmpty) return false;

    try {
      // Fetching profile is a good lightweight check that requires authentication.
      // We force a network call by not returning early from cache if we want to confirm with backend.
      // However, fetchProfile itself has cache logic. Let's use a direct minimal call.
      final userId = await _storage.read(key: 'lpu_userId');
      final deviceId =
          await _storage.read(key: 'lpu_deviceId') ?? 'flutter-123';

      final url =
          'https://ums.lpu.in/umswebservice/umswebservice.svc/StudentBasicInfoForService/$userId/$token/$deviceId/null/null';
      final resp = await _dio.get(url);

      // If we got here, it means the interceptor didn't reject the request.
      // But we should also check the body for errors.
      return !_isSessionExpired(resp.data);
    } catch (e) {
      print('[AUTH_SERVICE] Session validation failed: $e');
      return false;
    }
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
    await _cache.invalidateAll(); // clear all API caches
    await _storage.deleteAll();
    updateLoginState(false);
  }
}
