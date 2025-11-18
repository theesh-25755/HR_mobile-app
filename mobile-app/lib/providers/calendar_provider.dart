// lib/providers/calendar_provider.dart

import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';
import 'dart:collection';

class CalendarProvider with ChangeNotifier {
  List<dynamic> _events = [];
  bool _isLoading = false;
  
  late Map<DateTime, List<dynamic>> _eventMap;

  bool get isLoading => _isLoading;
  Map<DateTime, List<dynamic>> get eventMap => _eventMap;

  CalendarProvider() {
    _eventMap = LinkedHashMap<DateTime, List<dynamic>>(
      equals: isSameDay,
      hashCode: getHashCode,
    );
  }

  Future<void> fetchEvents(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      _events = await ApiService.getEvents(token);
      _processEvents();
    } catch (e) {
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> addEvent(String token, Map<String, dynamic> eventData) async {
    _isLoading = true;
    notifyListeners();
    try {
      // --- THIS IS THE FIX (PART 1) ---
      // We now receive UTC dates, so we just format them.
      eventData['startDate'] = (eventData['startDate'] as DateTime).toIso8601String();
      eventData['endDate'] = (eventData['endDate'] as DateTime).toIso8601String();
      // --- END FIX ---

      await ApiService.createEvent(token, eventData);
      
      await fetchEvents(token);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  void _processEvents() {
    _eventMap.clear();
    for (final event in _events) {
      try {
        // --- THIS IS THE FIX (PART 2) ---
        // Parse the UTC string, and convert it to the phone's local time
        final localStartDate = DateTime.parse(event['startDate']).toLocal();
        
        // Use the local date parts (year, month, day) to create the UTC key
        // This ensures Nov 29 (UTC) becomes Nov 30 (Local)
        final dateKey = DateTime.utc(localStartDate.year, localStartDate.month, localStartDate.day);
        // --- END FIX ---

        if (_eventMap[dateKey] == null) {
          _eventMap[dateKey] = [];
        }
        _eventMap[dateKey]!.add(event);
      } catch (e) {
        print('Error processing event date: $e');
      }
    }
    notifyListeners();
  }

  // Helper functions for LinkedHashMap
  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }
}