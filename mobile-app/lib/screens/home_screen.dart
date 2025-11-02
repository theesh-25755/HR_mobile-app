// lib/screens/home_screen.dart

import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/providers/leave_provider.dart';
import 'package:mobile_app/providers/notification_provider.dart';
import 'package:mobile_app/widgets/drawer_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        Provider.of<LeaveProvider>(context, listen: false).fetchMyLeaves(token);
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- PROVIDERS ---
    final authProvider = Provider.of<AuthProvider>(context);
    final leaveProvider = Provider.of<LeaveProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final user = authProvider.user;
    final String role = user?['role'] ?? 'employee';

    // --- DYNAMIC TITLES ---
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
      
      // --- WRAPPED THE STACK IN A BUILDER ---
      body: Builder(
        builder: (BuildContext bodyContext) { // This new 'bodyContext' can find the drawer
          return Stack( // Use a Stack to layer background and content
            children: [
              // 1. The Background Image
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/back1.png'), // Your background image
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 2. The Dashboard Content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      _buildFrostedHeader(
                        context: bodyContext, // <-- PASSED THE NEW CONTEXT
                        title: dashboardTitle,
                        chipText: chipText,
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
                            value: '18', // Still hardcoded
                            unit: 'days',
                            icon: Icons.calendar_today,
                            color: Colors.orange,
                          ),
                          _buildStatCard(
                            title: 'Attendance This Month',
                            value: '22/23', // Still hardcoded
                            unit: 'days',
                            icon: Icons.access_time,
                            color: Colors.blue,
                          ),
                          _buildStatCard(
                            title: 'Pending Requests',
                            value: leaveProvider.pendingCount.toString(),
                            icon: Icons.pending_actions,
                            color: Colors.red,
                          ),
                          _buildStatCard(
                            title: 'Notifications',
                            value: notificationProvider.unreadCount.toString(),
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
              ),
            ],
          );
        }
      ),
    );
  }

  // --- HEADER WIDGET (NOW USES THE CORRECT CONTEXT) ---
  Widget _buildFrostedHeader({
    required BuildContext context, // This context now comes from the Builder
    required String title,
    required String chipText,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black),
                    onPressed: () {
                      // This will now work correctly
                      Scaffold.of(context).openDrawer(); 
                    },
                  ),
                  
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  Chip(
                    label: Text(chipText),
                    backgroundColor: Colors.blue.shade900,
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 4.0), 
                child: const Text(
                  'Overview of your work status and activities',
                  style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // --- END MODIFIED WIDGET ---

  // Helper for Stat Cards
  Widget _buildStatCard({
    required String title,
    required String value,
    String? unit,
    required IconData icon,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4), // Make it readable
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
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
                    style: const TextStyle(color: Colors.black87, fontSize: 14), // Dark text
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black), // Dark text
                      ),
                      if (unit != null) const SizedBox(width: 4),
                      if (unit != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3.0),
                          child: Text(
                            unit,
                            style: const TextStyle(fontSize: 14, color: Colors.black87), // Dark text
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4), // Make it readable
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black), // Dark text
                  ),
                ],
              ),
              const Divider(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }

  // This helper is unchanged, text is already dark
  Widget _buildActionTile({required String title, required String status}) {
    final bool isActive = status == 'Active';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.black)), // Added dark color
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