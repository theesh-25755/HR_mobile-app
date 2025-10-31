// lib/screens/notifications_screen.dart

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: notifProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final token = Provider.of<AuthProvider>(context, listen: false).token;
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
                          color: Color(0xFFC62828)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Stay updated with system and HR alerts',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
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
    );
  }

  // Widget for the "All", "Unread", "Read" tabs
  Widget _buildFilterTabs(NotificationProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12.0),
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
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8.0),
        
        // --- FIX IS HERE ---
        // Replace 'borderSide' with 'borderColor' and 'selectedBorderColor'
        borderColor: Colors.transparent,
        selectedBorderColor: Colors.transparent,
        // --- END FIX ---

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
    );
  }

  // Widget for a single notification card
  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isUnread = notification['status'] == 'unread';

    return Card(
      elevation: 2.0,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      fontSize: 18, fontWeight: FontWeight.bold),
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
            const Divider(height: 24),
            Text(
              notification['message'] ?? 'No message content.',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}