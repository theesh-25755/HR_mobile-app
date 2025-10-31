import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android Emulator to connect to localhost
  static const String _baseUrl = "http://localhost:5000";

  // Handles the /login route
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response,
      // then parse the JSON.
      return jsonDecode(response.body);
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to login. Status code: ${response.statusCode}');
    }
  }
  // ... inside ApiService class, after updateProfile function ...

  // Handles GET /my-leave-applications
  static Future<List<dynamic>> getMyLeaveApplications(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/my-leave-applications'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Send the token
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load leave applications');
    }
  }
// ... inside ApiService class, after getMyLeaveApplications ...

  // Handles GET /notifications
  static Future<List<dynamic>> getNotifications(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Send the token
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load notifications');
    }
  }
  // We will add more functions here (getProfile, getLeaves, etc.)
}