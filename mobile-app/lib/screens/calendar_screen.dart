// lib/screens/calendar_screen.dart

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
    
    // Use addPostFrameCallback to run this after the build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDataAndSetSelectedEvents(); // <-- UPDATED
    });
  }

  // --- NEW HELPER FUNCTION ---
  // Fetches data AND updates the list for the selected day
  Future<void> _fetchDataAndSetSelectedEvents() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    
    // Fetch the events from the provider
    await Provider.of<CalendarProvider>(context, listen: false).fetchEvents(token);
    
    // NOW update the selected events for the initially selected day
    if (mounted) { // Check if the widget is still in the tree
      _onDaySelected(_selectedDay!, _focusedDay);
    }
  }
  // --- END NEW FUNCTION ---

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
    // Get events for the newly selected day
    _selectedEvents.value = Provider.of<CalendarProvider>(context, listen: false)
        .eventMap[DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day)] ?? [];
  }

  void _showAddEventDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController();
    final _descController = TextEditingController();
    
    DateTime? _startDate = _selectedDay ?? DateTime.now();
    DateTime? _endDate = _selectedDay ?? DateTime.now();
    String _eventType = 'event'; // Default value
    bool _isSaving = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to manage the dialog's internal state
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
                      // Event Type Dropdown
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
                      // Date Pickers
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
                              // Default end date to start date
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
                            firstDate: _startDate!, // Can't be before start date
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
                        
                        // Close the dialog on success
                        Navigator.of(dialogContext).pop();
                        // Refresh event list for the day
                        _onDaySelected(_selectedDay!, _focusedDay); 

                        // --- ADDED THIS SUCCESS MESSAGE ---
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Event added successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // --- END NEW CODE ---

                      } catch (e) {
                        // Show error
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
      appBar: AppBar(
        title: const Text('Office Calendar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: (day) {
              // This is what puts the marker on the calendar
              return calendarProvider.eventMap[DateTime.utc(day.year, day.month, day.day)] ?? [];
            },
            calendarStyle: CalendarStyle(
              // This styles the marker
              markerDecoration: BoxDecoration(
                color: Colors.red.shade700,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: ValueListenableBuilder<List<dynamic>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return const Center(
                    child: Text('No events for this day.'),
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
          : null, // No button if not HR
    );
  }

  Widget _buildEventTile(Map<String, dynamic> event) {
    bool isHoliday = event['eventType'] == 'holiday';
    return Card(
      elevation: 2.0,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(
          isHoliday ? Icons.celebration : Icons.event,
          color: isHoliday ? Colors.blue.shade700 : Colors.red.shade700,
        ),
        title: Text(
          event['title'] ?? 'No Title',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(event['description'] ?? 'No Description'),
      ),
    );
  }
}