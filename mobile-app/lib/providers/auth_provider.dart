// ...existing code...
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _profileData;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get profileData => _profileData;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  // Function to handle login
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);

      _token = response['access_token'];
      _user = response['user'];

      // Save the token to device storage
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) await prefs.setString('token', _token!);

      // populate profileData from user payload (or call API later)
      _profileData = _user != null ? Map<String, dynamic>.from(_user!) : {};

      notifyListeners();
    } catch (e) {
      // rethrow so UI can handle it
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Function to log out
  Future<void> logout() async {
    _token = null;
    _user = null;
    _profileData = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    notifyListeners();
  }

  // Load profile (replace with real API call later)
  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_user != null) {
        _profileData = Map<String, dynamic>.from(_user!);
      } else {
        _profileData = {}; // fallback
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save profile locally (replace with real API call later)
  Future<void> saveProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      _profileData = {...?_profileData, ...data};
      // TODO: call ApiService.updateProfile(data) to persist to server
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
// ...existing code...