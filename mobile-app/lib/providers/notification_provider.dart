// lib/providers/notification_provider.dart

import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';

// An enum to define our filter states safely
enum NotificationFilter { all, unread, read }

class NotificationProvider with ChangeNotifier {
  List<dynamic> _allNotifications = [];
  bool _isLoading = false;
  NotificationFilter _filter = NotificationFilter.all; // Default filter is "All"

  bool get isLoading => _isLoading;
  NotificationFilter get filter => _filter;

  // This getter filters the list based on the current state
  List<dynamic> get filteredNotifications {
    if (_filter == NotificationFilter.unread) {
      return _allNotifications.where((n) => n['status'] == 'unread').toList();
    }
    if (_filter == NotificationFilter.read) {
      return _allNotifications.where((n) => n['status'] == 'read').toList();
    }
    return _allNotifications; // Default is 'all'
  }

  // Function to fetch data from the API
  Future<void> fetchNotifications(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      _allNotifications = await ApiService.getNotifications(token);
    } catch (e) {
      print(e);
      // Handle error
    }

    _isLoading = false;
    notifyListeners();
  }

  // Function to change the active filter
  void setFilter(NotificationFilter newFilter) {
    _filter = newFilter;
    notifyListeners(); // Tell the UI to rebuild with the new filter
  }

  // TODO: Add a function here to mark notifications as read
  // This will require a new backend endpoint

  // --- NEW CODE ---
  // Getter for the dashboard to easily get the unread count
  int get unreadCount {
    return _allNotifications.where((n) => n['status'] == 'unread').length;
  }
  // --- END NEW CODE ---
}