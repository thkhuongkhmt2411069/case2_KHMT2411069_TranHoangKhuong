
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Headers dùng chung
  static Future<Map<String, String>> _headers() async {
    final token = await getToken();

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

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

    final result = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && result['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      final user = result['user'];

      await prefs.setString('token', result['token'].toString());
      await prefs.setString('userName', user['name']?.toString() ?? '');
      await prefs.setString('userEmail', user['email']?.toString() ?? '');
      await prefs.setString(
        'userId',
        (user['_id'] ?? user['id'] ?? '').toString(),
      );
    }

    return result;
  }

  // Lấy Token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Lấy tên người dùng
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  // Lấy ID người dùng
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Đăng xuất
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userId');
  }

  // Lấy danh sách công việc
  static Future<List<dynamic>> getTasks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: await _headers(),
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
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
      }),
    );

    final result = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(result['message'] ?? 'Tạo công việc thất bại');
    }

    return result;
  }

  // Cập nhật công việc
  static Future<Map<String, dynamic>> updateTask(
    String id,
    String title,
    String description,
    String status,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'status': status,
      }),
    );

    final result = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(result['message'] ?? 'Cập nhật thất bại');
    }

    return result;
  }

  // Xóa công việc
  static Future<void> deleteTask(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Xóa công việc thất bại');
    }
  }

  // Giao công việc
  static Future<Map<String, dynamic>> assignTask(
    String taskId,
    String email,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$taskId/assign'),
      headers: await _headers(),
      body: jsonEncode({'email': email}),
    );

    final result = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(result['message'] ?? 'Giao công việc thất bại');
    }

    return result;
  }

  // Chia sẻ công việc và phân quyền
  static Future<Map<String, dynamic>> shareTask(
    String taskId,
    String email,
    String role,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$taskId/share'),
      headers: await _headers(),
      body: jsonEncode({
        'email': email,
        'role': role,
      }),
    );

    final result = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(result['message'] ?? 'Chia sẻ công việc thất bại');
    }

    return result;
  }

  // Lấy danh sách thông báo
  static Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }

      if (data is Map && data['notifications'] is List) {
        return data['notifications'];
      }

      return [];
    }

    throw Exception('Không thể tải thông báo');
  }

  // Đánh dấu một thông báo đã đọc
  static Future<void> markNotificationRead(String id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể đánh dấu thông báo đã đọc');
    }
  }

  // Đánh dấu tất cả thông báo đã đọc
  static Future<void> markAllNotificationsRead() async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể đánh dấu tất cả thông báo đã đọc');
    }
  }

  // Lấy thống kê công việc
  static Future<Map<String, dynamic>> getStatistics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/statistics'),
      headers: await _headers(),
    );

    final result = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(result['message'] ?? 'Không thể tải thống kê');
    }

    return result['statistics'] ?? result;
  }
}
