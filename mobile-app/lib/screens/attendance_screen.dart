// lib/screens/attendance_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/providers/attendance_provider.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data when the screen first loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        Provider.of<AttendanceProvider>(context, listen: false)
            .fetchMyAttendance(token);
      }
    });
  }

  // --- NEW HELPER FUNCTION ---
  // Converts a UTC ISO string to a local time string (e.g., "13:34")
  String _formatTime(String? isoString) {
    if (isoString == null) return "N/A";
    try {
      final dateTime = DateTime.parse(isoString);
      final localTime = dateTime.toLocal(); // Convert to local time
      return DateFormat('HH:mm').format(localTime); // Format as 13:34
    } catch (e) {
      return "N/A";
    }
  }
  // --- END NEW HELPER ---

  @override
  Widget build(BuildContext context) {
    // Listen to the provider
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: attendanceProvider.isLoading && attendanceProvider.attendanceRecords.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (token != null) {
                  await attendanceProvider.fetchMyAttendance(token);
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attendance Dashboard',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC62828)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage and view your daily attendance records',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),

                    // Check In / Check Out Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                            label: const Text('Check In', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: (attendanceProvider.canCheckIn && !attendanceProvider.isLoading && token != null)
                                ? () => attendanceProvider.checkIn(token)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.exit_to_app, color: Colors.white),
                            label: const Text('Check Out', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC62828),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: (attendanceProvider.canCheckOut && !attendanceProvider.isLoading && token != null)
                                ? () => attendanceProvider.checkOut(token)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        attendanceProvider.todayStatus,
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Active Hours Overview
                    _buildSection(
                      title: 'Active Hours Overview',
                      child: SizedBox(
                        height: 200,
                        child: _buildBarChart(attendanceProvider.attendanceRecords),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Attendance History
                    _buildSection(
                      title: 'Attendance History',
                      child: _buildAttendanceTable(attendanceProvider.attendanceRecords),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper for Section Cards
  Widget _buildSection({required String title, required Widget child}) {
    return Card(
      elevation: 2.0,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  // Helper for the Bar Chart
  Widget _buildBarChart(List<dynamic> records) {
    // Get last 7 days of records
    final recentRecords = records.take(7).toList().reversed;
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10, // Max 10 hours
        barGroups: recentRecords.map((record) {
          final date = DateTime.parse(record['date']);
          final hours = (record['workedHours'] ?? 0.0).toDouble();
          
          return BarChartGroupData(
            x: date.millisecondsSinceEpoch,
            barRods: [
              BarChartRodData(
                toY: hours,
                color: const Color(0xFFC62828),
                width: 16,
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(DateFormat('MM/dd').format(date), style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true, drawVerticalLine: false),
      ),
    );
  }

  // Helper for the Attendance Table
  Widget _buildAttendanceTable(List<dynamic> records) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Check In', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Check Out', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('Hours', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        // Table Body
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!))
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(record['date'] ?? 'N/A')),
                  // --- UPDATED THESE LINES ---
                  Expanded(flex: 2, child: Text(_formatTime(record['checkInTime']))),
                  Expanded(flex: 2, child: Text(_formatTime(record['checkOutTime']))),
                  // --- END UPDATES ---
                  Expanded(flex: 1, child: Text(record['workedHours']?.toString() ?? 'N/A')),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}