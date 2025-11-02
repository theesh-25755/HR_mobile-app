// lib/screens/leave_status_screen.dart

import 'dart:ui'; // <-- ADDED for ImageFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/providers/leave_provider.dart';

class LeaveStatusScreen extends StatefulWidget {
  const LeaveStatusScreen({super.key});

  @override
  State<LeaveStatusScreen> createState() => _LeaveStatusScreenState();
}

class _LeaveStatusScreenState extends State<LeaveStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        Provider.of<LeaveProvider>(context, listen: false).fetchMyLeaves(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaveProvider = Provider.of<LeaveProvider>(context);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    return Scaffold(
      // --- MODIFICATIONS FOR FROSTED GLASS ---
      extendBodyBehindAppBar: true, // Allow body to go behind AppBar
      appBar: AppBar(
        title: const Text('Leave Status'),
        backgroundColor: Colors.transparent, // Make AppBar transparent
        foregroundColor: Colors.white, // Make title and back arrow white
        elevation: 0, // Remove shadow
      ),
      backgroundColor: Colors.transparent, // Remove solid background
      // --- END MODIFICATIONS ---
      
      body: Stack( // Stack to hold background and content
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
          SafeArea( // Keep content below status bar
            child: leaveProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : RefreshIndicator(
                    onRefresh: () async {
                      if (token != null) {
                        await Provider.of<LeaveProvider>(context, listen: false).fetchMyLeaves(token);
                      }
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Leave Status',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), // <-- CHANGED
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Track your leave applications and history',
                            style: TextStyle(fontSize: 16, color: Colors.white70), // <-- CHANGED
                          ),
                          const SizedBox(height: 24),

                          // Stat Cards Grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12.0,
                            crossAxisSpacing: 12.0,
                            childAspectRatio: 2.0, // Wider cards
                            children: [
                              _buildStatCard('Approved', leaveProvider.approvedCount.toString(), const Color.fromARGB(255, 27, 134, 31)),
                              _buildStatCard('Pending', leaveProvider.pendingCount.toString(), const Color.fromARGB(255, 205, 109, 14)),
                              _buildStatCard('Rejected', leaveProvider.rejectedCount.toString(), const Color.fromARGB(255, 235, 45, 32)),
                              _buildStatCard('Total Days', leaveProvider.totalDays.toString(), const Color.fromARGB(255, 11, 119, 207)),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // --- MODIFIED LEAVE HISTORY SECTION ---
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Leave History',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              // TODO: Implement Export PDF
                                            },
                                            icon: const Icon(Icons.download, size: 18),
                                            label: const Text('Export PDF'),
                                          ),
                                        ],
                                      ),
                                      const Text(
                                        'View and manage your leave applications',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      const SizedBox(height: 16),
                                      // Search Bar
                                      TextField(
                                        style: const TextStyle(color: Colors.black),
                                        decoration: InputDecoration(
                                          hintText: 'Search leave applications...',
                                          hintStyle: const TextStyle(color: Colors.black54),
                                          prefixIcon: const Icon(Icons.search, color: Colors.black87),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.3),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          // TODO: Implement Search
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Leave List
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: leaveProvider.leaves.length,
                                        itemBuilder: (context, index) {
                                          final leave = leaveProvider.leaves[index];
                                          return _buildLeaveTile(leave);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- MODIFIED STAT CARD HELPER ---
  Widget _buildStatCard(String title, String value, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // Center content
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // --- END MODIFIED HELPER ---

  // Helper for the list items (this can stay the same, it looks good on the frosted card)
  Widget _buildLeaveTile(Map<String, dynamic> leave) {
    String leaveType = leave['leaveType']?.toString() ?? 'Leave';
    
    if (leaveType.isNotEmpty) {
      leaveType = leaveType[0].toUpperCase() + leaveType.substring(1).toLowerCase();
    }

    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.7), // Make list tiles slightly transparent
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          leaveType,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        subtitle: Text(
          '${leave['fromDate'] ?? 'N/A'} to ${leave['toDate'] ?? 'N/A'} (${leave['days'] ?? 0} days)',
          style: const TextStyle(color: Colors.black87),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusChip(leave['finalStatus']?.toString() ?? 'Pending'),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.black87),
          ],
        ),
        onTap: () {
          // TODO: Implement View Details Page
        },
      ),
    );
  }

  // Helper for the status chip
  Widget _buildStatusChip(String status) {
    Color color;
    Color textColor;
    if (status == 'Approved') {
      color = Colors.green.shade100;
      textColor = Colors.green.shade900;
    } else if (status == 'Rejected') {
      color = Colors.red.shade100;
      textColor = Colors.red.shade900;
    } else {
      color = Colors.orange.shade100;
      textColor = Colors.orange.shade900;
    }

    return Chip(
      label: Text(status),
      labelStyle: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0),
    );
  }
}