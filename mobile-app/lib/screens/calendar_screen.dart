// lib/screens/calendar_screen.dart

import 'dart:ui'; // <-- ADDED for ImageFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/providers/calendar_provider.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late ValueNotifier<List<dynamic>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDataAndSetSelectedEvents();
    });
  }

  Future<void> _fetchDataAndSetSelectedEvents() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    
    await Provider.of<CalendarProvider>(context, listen: false).fetchEvents(token);
    
    if (mounted) {
      _onDaySelected(_selectedDay!, _focusedDay);
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
    _selectedEvents.value = Provider.of<CalendarProvider>(context, listen: false)
        .eventMap[DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day)] ?? [];
  }

  void _showAddEventDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController();
    final _descController = TextEditingController();
    
    DateTime? _startDate = _selectedDay ?? DateTime.now();
    DateTime? _endDate = _selectedDay ?? DateTime.now();
    String _eventType = 'event';
    bool _isSaving = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Event'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter a title' : null,
                      ),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _eventType,
                        decoration: const InputDecoration(labelText: 'Event Type'),
                        items: const [
                          DropdownMenuItem(value: 'event', child: Text('Event')),
                          DropdownMenuItem(value: 'holiday', child: Text('Holiday')),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            _eventType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Text('Start Date: ${DateFormat('yyyy-MM-dd').format(_startDate!)}'),
                      ElevatedButton(
                        child: const Text('Select Start Date'),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate!,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _startDate = date;
                              if (_endDate!.isBefore(_startDate!)) {
                                _endDate = _startDate;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Text('End Date: ${DateFormat('yyyy-MM-dd').format(_endDate!)}'),
                      ElevatedButton(
                        child: const Text('Select End Date'),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate!,
                            firstDate: _startDate!,
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _endDate = date;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Save'),
                  onPressed: _isSaving ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setDialogState(() { _isSaving = true; });
                      
                      final token = Provider.of<AuthProvider>(context, listen: false).token;
                      final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);

                      try {
                        await calendarProvider.addEvent(token!, {
                          "title": _titleController.text,
                          "description": _descController.text,
                          "startDate": _startDate,
                          "endDate": _endDate,
                          "eventType": _eventType,
                        });
                        
                        Navigator.of(dialogContext).pop();
                        _onDaySelected(_selectedDay!, _focusedDay); 

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Event added successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );

                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add event: $e'), backgroundColor: Colors.red),
                        );
                      } finally {
                        setDialogState(() { _isSaving = false; });
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = Provider.of<CalendarProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isHR = authProvider.user?['role'] == 'hr_manager' || authProvider.user?['role'] == 'super_admin';

    return Scaffold(
      // --- MODIFICATIONS FOR FROSTED GLASS ---
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Office Calendar'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.transparent,
      // --- END MODIFICATIONS ---
      
      body: Stack(
        children: [
          // 1. The Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/back1.png'), // Use same background
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // 2. The Content
          SafeArea(
            child: Column(
              children: [
                // --- CALENDAR IS NOW WRAPPED IN FROSTED GLASS ---
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: _onDaySelected,
                        eventLoader: (day) {
                          return calendarProvider.eventMap[DateTime.utc(day.year, day.month, day.day)] ?? [];
                        },
                        // --- STYLES UPDATED TO BE READABLE (DARK TEXT) ---
                        calendarStyle: CalendarStyle(
                          markerDecoration: BoxDecoration(
                            color: Colors.red.shade700,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.red.shade200,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Colors.red.shade700,
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle: const TextStyle(color: Colors.black87),
                          weekendTextStyle: TextStyle(color: Colors.red.shade900),
                          outsideTextStyle: TextStyle(color: Colors.grey.shade600),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black),
                          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: const TextStyle(color: Colors.black54),
                          weekendStyle: TextStyle(color: Colors.red.shade900),
                        ),
                        // --- END STYLE UPDATES ---
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                      ),
                    ),
                  ),
                ),
                
                // --- EVENT LIST TITLE ---
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(Icons.list_alt, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Events on this day',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // --- EVENT LIST IS NOW WRAPPED IN FROSTED GLASS ---
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: ValueListenableBuilder<List<dynamic>>(
                          valueListenable: _selectedEvents,
                          builder: (context, value, _) {
                            if (value.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No events for this day.',
                                  style: TextStyle(color: Colors.black87), // <-- CHANGED
                                ),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: value.length,
                              itemBuilder: (context, index) {
                                final event = value[index];
                                return _buildEventTile(event);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isHR
          ? FloatingActionButton(
              onPressed: () {
                _showAddEventDialog(context);
              },
              backgroundColor: Colors.red.shade700,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- MODIFIED EVENT TILE HELPER ---
  Widget _buildEventTile(Map<String, dynamic> event) {
    bool isHoliday = event['eventType'] == 'holiday';
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.7), // Make list tiles slightly transparent
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(
          isHoliday ? Icons.celebration : Icons.event,
          color: isHoliday ? Colors.blue.shade700 : Colors.red.shade700,
        ),
        title: Text(
          event['title'] ?? 'No Title',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        subtitle: Text(
          event['description'] ?? 'No Description',
          style: const TextStyle(color: Colors.black87),
        ),
      ),
    );
  }
}