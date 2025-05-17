import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  final String baseUrl;
  String? authToken;

  ApiService(this.baseUrl) {
    if (kDebugMode) {
      print('API Service initialized with base URL: $baseUrl');
    }
  }

  // Đặt token sau khi đăng nhập
  void setAuthToken(String token) {
    authToken = token;
  }

  // Xóa token khi đăng xuất
  void clearAuthToken() {
    authToken = null;
  }

  // Hàm hỗ trợ để thêm header Authorization nếu có token
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  // Đăng ký người dùng
  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String passwordConfirm,
    required String username,
  }) async {
    final url = Uri.parse('$baseUrl/signup/');
    final body = jsonEncode({
      'email': email,
      'password': password,
      'password_confirm': passwordConfirm,
      'username': username,
    });

    final response = await http.post(
      url,
      headers: _getHeaders(),
      body: body,
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to sign up');
    }
  }

  // Đăng nhập người dùng
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login/');
    final body = jsonEncode({
      'email': email,
      'password': password,
    });

    final response = await http.post(
      url,
      headers: _getHeaders(),
      body: body,
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      setAuthToken(result['token']); // Lưu token
      return result;
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to login');
    }
  }

  // Lấy thông tin người dùng
  Future<Map<String, dynamic>> getMe() async {
    if (authToken == null) {
      throw Exception('No authentication token found');
    }

    final url = Uri.parse('$baseUrl/getMe/');

    final response = await http.get(
      url,
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to get user info');
    }
  }

  // Lấy dữ liệu thời tiết hôm nay
  Future<List<dynamic>> getWeatherDataDaily() async {
    final url = Uri.parse('$baseUrl/weather/daily');

    final response = await http.get(
      url,
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to get daily weather data');
    }
  }

  // Lấy dữ liệu thời tiết trong khoảng thời gian
  Future<List<dynamic>> getWeatherDataByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    // Convert YYYY-MM-DD to DD/MM/YYYY
    String formatDate(String date) {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return date;
    }

    final url = Uri.parse('$baseUrl/weather/getDayRange/').replace(
      queryParameters: {
        'start_date': formatDate(startDate),
        'end_date': formatDate(endDate),
      },
    );

    final response = await http.get(
      url,
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to get weather data by date range');
    }
  }

  // Gửi email cảnh báo
  Future<Map<String, dynamic>> sendAlertEmail({
    required double tempThreshold,
    required double humidThreshold,
    required double pressureThreshold,
    required String emailTo,
  }) async {

    final url = Uri.parse('$baseUrl/send_alert_email/');
    final body = jsonEncode({
      'temp_threshold': tempThreshold,
      'humid_threshold': humidThreshold,
      'pressure_threshold': pressureThreshold,
      'email_to': emailTo,
    });

    try {
      final response = await http.post(
        url,
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? errorBody['message'] ?? 'Failed to send alert email');
      }
    } catch (e) {
      print('Error sending alert email: $e');
      print('Request URL: $url');
      print('Request body: $body');
      rethrow;
    }
  }
}