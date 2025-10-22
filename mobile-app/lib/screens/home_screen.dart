// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/providers/leave_provider.dart';
import 'package:mobile_app/providers/notification_provider.dart';
import 'package:mobile_app/widgets/drawer_menu.dart';

// --- CHANGED TO STATEFULWIDGET ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- NEW CODE ---
  // This function fetches all the dashboard data at once
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to run this after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get the token from AuthProvider
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        // Fetch data from both providers
        Provider.of<LeaveProvider>(context, listen: false).fetchMyLeaves(token);
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(token);
      }
    });
  }
  // --- END NEW CODE ---

  @override
  Widget build(BuildContext context) {
    // Get the auth provider to find the user's role
    final authProvider = Provider.of<AuthProvider>(context);
    
    // --- NEW CODE ---
    // Listen to the other providers to get the live data
    final leaveProvider = Provider.of<LeaveProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    // --- END NEW CODE ---

    final user = authProvider.user;
    final String role = user?['role'] ?? 'employee'; // Get the role

    // Create the dynamic titles based on the role
    String dashboardTitle;
    String chipText;

    if (role == 'hr_manager') {
      dashboardTitle = 'HR Manager Dashboard';
      chipText = 'HR MANAGER';
    } else if (role == 'supervisor') {
      dashboardTitle = 'Supervisor Dashboard';
      chipText = 'SUPERVISOR';
    } else if (role == 'project_manager') {
      dashboardTitle = 'Project Manager Dashboard';
      chipText = 'PROJECT MANAGER';
    } else {
      dashboardTitle = 'Employee Dashboard';
      chipText = 'EMPLOYEE';
    }

    return Scaffold(
      drawer: const DrawerMenu(),
      appBar: AppBar(
        title: Text(dashboardTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // Makes icons and title black
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              label: Text(chipText),
              backgroundColor: Colors.blue.shade900,
              labelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8F9FA), // A very light grey
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview of your work status and activities',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // Stat Cards (2x2 Grid)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12.0,
              crossAxisSpacing: 12.0,
              childAspectRatio: 1.2,
              children: [
                _buildStatCard(
                  title: 'Leave Balance',
                  value: '18', // Still hardcoded for now
                  unit: 'days',
                  icon: Icons.calendar_today,
                  color: Colors.orange,
                ),
                _buildStatCard(
                  title: 'Attendance This Month',
                  value: '22/23', // Still hardcoded for now
                  unit: 'days',
                  icon: Icons.access_time,
                  color: Colors.blue,
                ),
                
                // --- UPDATED ---
                _buildStatCard(
                  title: 'Pending Requests',
                  value: leaveProvider.pendingCount.toString(), // Now dynamic
                  icon: Icons.pending_actions,
                  color: Colors.red,
                ),
                // --- UPDATED ---
                _buildStatCard(
                  title: 'Notifications',
                  value: notificationProvider.unreadCount.toString(), // Now dynamic
                  icon: Icons.notifications,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            _buildSection(
              title: 'Quick Actions',
              icon: Icons.rocket_launch,
              child: Column(
                children: [
                  _buildActionTile(title: 'Apply for Leave', status: 'Active'),
                  _buildActionTile(title: 'Mark Attendance', status: 'Pending'),
                  _buildActionTile(title: 'View Payslip', status: 'Active'),
                  _buildActionTile(title: 'Update Profile', status: 'Pending'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Recent Activities
            _buildSection(
              title: 'Recent Activities',
              icon: Icons.history,
              child: Column(
                children: [
                  _buildActionTile(title: 'Leave approved - Annual Leave', status: 'Active'),
                  _buildActionTile(title: 'Attendance marked for today', status: 'Pending'),
                  _buildActionTile(title: 'Profile updated', status: 'Active'),
                  _buildActionTile(title: 'New policy notification', status: 'Pending'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Stat Cards
  Widget _buildStatCard({
    required String title,
    required String value,
    String? unit,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2.0,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 30, color: color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if (unit != null) const SizedBox(width: 4),
                    if (unit != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3.0),
                        child: Text(
                          unit,
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for List Sections
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
            Row(
              children: [
                Icon(icon, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  // Helper for List Tiles
  Widget _buildActionTile({required String title, required String status}) {
    final bool isActive = status == 'Active';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Chip(
            label: Text(status),
            labelStyle: TextStyle(
              color: isActive ? Colors.green.shade900 : Colors.orange.shade900,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            backgroundColor: isActive ? Colors.green.shade100 : Colors.orange.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0),
          ),
        ],
      ),
    );
  }
}