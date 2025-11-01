// lib/providers/attendance_provider.dart

import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:intl/intl.dart';

class AttendanceProvider with ChangeNotifier {
  List<dynamic> _attendanceRecords = [];
  bool _isLoading = false;
  
  // Button states
  bool _canCheckIn = false;
  bool _canCheckOut = false;
  String _todayStatus = "Loading...";

  List<dynamic> get attendanceRecords => _attendanceRecords;
  bool get isLoading => _isLoading;
  bool get canCheckIn => _canCheckIn;
  bool get canCheckOut => _canCheckOut;
  String get todayStatus => _todayStatus;

  // Function to fetch data and update button states
  Future<void> fetchMyAttendance(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      _attendanceRecords = await ApiService.getMyAttendance(token);
      _updateButtonStates();
    } catch (e) {
      print(e);
      _todayStatus = "Error loading data";
    }

    _isLoading = false;
    notifyListeners();
  }

  // Check In
  Future<void> checkIn(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      await ApiService.checkIn(token);
      await fetchMyAttendance(token); // Re-fetch data to update UI
    } catch (e) {
      print(e);
      // You can show a SnackBar from the UI here
    }
    _isLoading = false;
    notifyListeners();
  }

  // Check Out
  Future<void> checkOut(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      await ApiService.checkOut(token);
      await fetchMyAttendance(token); // Re-fetch data to update UI
    } catch (e) {
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  // Logic to determine button states
  void _updateButtonStates() {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Find a record for today
    var todayRecord = _attendanceRecords.firstWhere(
      (record) => record['date'] == today,
      orElse: () => null,
    );

    if (todayRecord == null) {
      // No record for today
      _canCheckIn = true;
      _canCheckOut = false;
      _todayStatus = "You have not checked in today.";
    } else {
      // Record exists for today
      if (todayRecord['checkOutTime'] == null) {
        // Checked in, but not checked out
        _canCheckIn = false;
        _canCheckOut = true;
        _todayStatus = "Checked in at ${todayRecord['checkInTime']}.";
      } else {
        // Already checked in and out
        _canCheckIn = false;
        _canCheckOut = false;
        _todayStatus = "Completed for today. Worked ${todayRecord['workedHours']}h.";
      }
    }
  }
}