import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';

// Import all the screens
import 'package:mobile_app/screens/leave_status_screen.dart';
import 'package:mobile_app/screens/profile_screen.dart';
import 'package:mobile_app/screens/notifications_screen.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final profile = authProvider.profileData; // Get detailed profile data

    // Get the base64 profile image string
    final String? base64Image = profile?['profile_image'];
    
    Widget profileAvatar;
    
    if (base64Image != null && base64Image.isNotEmpty) {
      // Decode the base64 string
      final imageBytes = base64Decode(base64Image.split(',').last);
      profileAvatar = CircleAvatar(
        radius: 20, // Small avatar for the drawer
        backgroundImage: MemoryImage(imageBytes),
      );
    } else {
      // Default avatar
      profileAvatar = const CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        child: Icon(Icons.person, color: Color(0xFFC62828)),
      );
    }

    return Drawer(
      child: Container(
        color: const Color(0xFFC62828), // Dark Red
        child: Column(
          children: [
            // Header
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 16), // Extra top padding
                child: Row(
                  children: [
                    Image.asset('assets/images/logo.png', height: 40, color: Colors.white), 
                    const SizedBox(width: 12),
                    const Text(
                      'HRMS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Menu Items
            _buildDrawerItem(
              context: context,
              icon: Icons.dashboard,
              title: 'Dashboard',
              onTap: () {
                // We are already on Home, so just close the drawer
                Navigator.of(context).pop();
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.history,
              title: 'Leave Status',
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LeaveStatusScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.person,
              title: 'Profile',
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),

            // Spacer to push footer to bottom
            const Spacer(),

            // Footer (User Info & Sign Out)
            const Divider(color: Colors.white30),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  profileAvatar, // Use the avatar we built
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?['name'] ?? 'User',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user?['role'] ?? 'Employee',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFC62828)),
                title: const Text(
                  'Sign out',
                  style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for a drawer item
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
      hoverColor: Colors.red.shade900,
    );
  }
}