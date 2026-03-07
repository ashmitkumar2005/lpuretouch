import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';

class AttendanceService {
  final Dio _dio = Dio();
  final AuthService _authService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  final String _baseUrl = 'https://ums.lpu.in/umswebservice/umswebservice.svc';

  AttendanceService(this._authService);

  Future<dynamic> fetchAttendance() async {
    final token = await _storage.read(key: 'lpu_token');
    final userId = await _storage.read(key: 'lpu_userId');
    final deviceId = await _storage.read(key: 'lpu_deviceId') ?? 'flutter-123';

    if (token == null || userId == null) {
      throw Exception('User is not logged in');
    }

    try {
      final response = await _dio.get(
        '$_baseUrl/StudentAttendanceForServiceNew/$userId/$token/$deviceId',
        options: Options(
          headers: {
            "Content-Type": "application/json"
          },
        ),
      );

      if (response.statusCode == 200) {
        // UMS usually returns a direct JSON array for this endpoint
        return response.data;
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch attendance: $e');
    }
  }
}

