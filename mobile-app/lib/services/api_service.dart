import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android Emulator to connect to localhost
  // Use http://localhost:5000 (or 5001) for Chrome
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
      return jsonDecode(response.body);
    } else {
      // Try to parse the error message from the backend
      String message = 'Failed to login. Status code: ${response.statusCode}';
      try {
        final error = jsonDecode(response.body);
        message = error['message'] ?? message;
      } catch (e) {
        // Do nothing if body is not valid JSON
      }
      throw Exception(message);
    }
  }

  // Handles GET /user-profile
  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/user-profile'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Send the token
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile');
    }
  }

  // Handles PUT /user-profile
  static Future<Map<String, dynamic>> updateProfile(
      String token, Map<String, String> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/user-profile'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Send the token
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile');
    }
  }

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

  // Handles GET /attendance/my
  static Future<List<dynamic>> getMyAttendance(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/attendance/my'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load attendance');
    }
  }

  // Handles POST /attendance/checkin
  static Future<Map<String, dynamic>> checkIn(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/attendance/checkin'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check in');
    }
  }

  // Handles POST /attendance/checkout
  static Future<Map<String, dynamic>> checkOut(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/attendance/checkout'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check out');
    }
  }

  

  // Handles GET /events
  static Future<List<dynamic>> getEvents(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/events'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load events');
    }
  }

  // Handles POST /events
  static Future<Map<String, dynamic>> createEvent(String token, Map<String, dynamic> eventData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/events'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(eventData),
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create event');
    }
  }
}