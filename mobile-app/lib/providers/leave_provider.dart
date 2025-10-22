// lib/providers/leave_provider.dart

import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';

class LeaveProvider with ChangeNotifier {
  List<dynamic> _leaves = [];
  bool _isLoading = false;

  // Stats for the cards
  int _approvedCount = 0;
  int _pendingCount = 0;
  int _rejectedCount = 0;
  int _totalDays = 0;

  // Getters for the UI
  List<dynamic> get leaves => _leaves;
  bool get isLoading => _isLoading;
  int get approvedCount => _approvedCount;
  int get pendingCount => _pendingCount;
  int get rejectedCount => _rejectedCount;
  int get totalDays => _totalDays;

  // Function to fetch data from the API
  Future<void> fetchMyLeaves(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      _leaves = await ApiService.getMyLeaveApplications(token);
      _calculateStats();
    } catch (e) {
      print(e);
      // Handle error
    }

    _isLoading = false;
    notifyListeners();
  }

  // Helper function to calculate the stats
  void _calculateStats() {
    // Reset counts
    _approvedCount = 0;
    _pendingCount = 0;
    _rejectedCount = 0;
    _totalDays = 0;

    for (var leave in _leaves) {
      String status = leave['finalStatus'] ?? 'Pending';
      if (status == 'Approved') {
        _approvedCount++;
        // Add the number of days from the leave record
        // We use '?? 0' as a safety check
        _totalDays += (leave['days'] ?? 0) as int;
      } else if (status == 'Pending') {
        _pendingCount++;
      } else if (status == 'Rejected') {
        _rejectedCount++;
      }
    }
  }
}