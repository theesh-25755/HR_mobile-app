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
  
  // --- NEW FUNCTION TO ADD EVENTS ---
  Future<void> addEvent(String token, Map<String, dynamic> eventData) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Convert DateTime objects to ISO 8601 strings for the API
      eventData['startDate'] = (eventData['startDate'] as DateTime).toIso8601String();
      eventData['endDate'] = (eventData['endDate'] as DateTime).toIso8601String();

      await ApiService.createEvent(token, eventData);
      
      // After successfully adding, refresh the event list
      await fetchEvents(token);
    } catch (e) {
      // If it fails, stop loading and re-throw the error
      _isLoading = false;
      notifyListeners();
      throw e;
    }
    // fetchEvents() will set isLoading to false and notify listeners on success
  }
  // --- END NEW FUNCTION ---

  void _processEvents() {
    _eventMap.clear();
    for (final event in _events) {
      try {
        final startDate = DateTime.parse(event['startDate']).toUtc();
        final dateKey = DateTime.utc(startDate.year, startDate.month, startDate.day);

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