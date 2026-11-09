
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Đăng nhập
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final result =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && result['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', result['token']);
      await prefs.setString('userName', result['user']['name']);
      await prefs.setString('userEmail', result['user']['email']);
    }

    return result;
  }

  // Lấy Token đã lưu
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Lấy danh sách công việc
  static Future<List<dynamic>> getTasks() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception('Không thể tải danh sách công việc');
  }

  // Tạo công việc
  static Future<Map<String, dynamic>> createTask(
    String title,
    String description,
  ) async {
    final token = await getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
      }),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // Cập nhật công việc
  static Future<Map<String, dynamic>> updateTask(
    String id,
    String title,
    String description,
    String status,
  ) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'status': status,
      }),
    );

    final result =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(result['message'] ?? 'Cập nhật thất bại');
    }

    return result;
  }

  // Xóa công việc
  static Future<void> deleteTask(String id) async {
    final token = await getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Xóa công việc thất bại');
    }
  }
}
