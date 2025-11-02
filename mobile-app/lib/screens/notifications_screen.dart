// lib/screens/notifications_screen.dart

import 'dart:ui'; // <-- ADDED for ImageFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data when the screen first loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        Provider.of<NotificationProvider>(context, listen: false)
            .fetchNotifications(token);
      }
    });
  }

  // Helper function to format the date
  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'N/A';
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the NotificationProvider
    final notifProvider = Provider.of<NotificationProvider>(context);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    return Scaffold(
      // --- MODIFICATIONS FOR FROSTED GLASS ---
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.transparent,
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
          SafeArea(
            child: notifProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : RefreshIndicator(
                    onRefresh: () async {
                      if (token != null) {
                        await notifProvider.fetchNotifications(token);
                      }
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white), // <-- CHANGED
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Stay updated with system and HR alerts',
                            style: TextStyle(fontSize: 16, color: Colors.white70), // <-- CHANGED
                          ),
                          const SizedBox(height: 24),

                          // Filter Tabs
                          _buildFilterTabs(notifProvider),

                          const SizedBox(height: 24),

                          // List of Notifications
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: notifProvider.filteredNotifications.length,
                            itemBuilder: (context, index) {
                              final notification =
                                  notifProvider.filteredNotifications[index];
                              return _buildNotificationCard(notification);
                            },
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

  // --- MODIFIED FILTER TABS HELPER ---
  Widget _buildFilterTabs(NotificationProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4), // Make it readable
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: ToggleButtons(
            isSelected: [
              provider.filter == NotificationFilter.all,
              provider.filter == NotificationFilter.unread,
              provider.filter == NotificationFilter.read,
            ],
            onPressed: (int index) {
              if (index == 0) {
                provider.setFilter(NotificationFilter.all);
              } else if (index == 1) {
                provider.setFilter(NotificationFilter.unread);
              } else {
                provider.setFilter(NotificationFilter.read);
              }
            },
            fillColor: Colors.red.shade700,
            selectedColor: Colors.white,
            color: Colors.black87, // Text color for unselected tabs
            borderRadius: BorderRadius.circular(8.0),
            borderColor: Colors.transparent,
            selectedBorderColor: Colors.transparent,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('All'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Unread'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Read'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // --- END MODIFIED HELPER ---

  // --- MODIFIED NOTIFICATION CARD HELPER ---
  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isUnread = notification['status'] == 'unread';

    // Replaced Card with frosted glass effect
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      notification['type'] ?? 'Notification',
                      style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.black), // <-- CHANGED
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(notification['createdAt']),
                      style: const TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    if (isUnread)
                      Chip(
                        label: const Text('unread'),
                        labelStyle: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        backgroundColor: Colors.red.shade100,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0),
                      ),
                  ],
                ),
                const Divider(height: 24, color: Colors.black26), // <-- CHANGED
                Text(
                  notification['message'] ?? 'No message content.',
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
}