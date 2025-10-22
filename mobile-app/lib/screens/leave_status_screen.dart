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
    // Fetch data when the screen first loads
    // We use addPostFrameCallback to wait for the widget to be built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        // Call the fetch function from our new provider
        Provider.of<LeaveProvider>(context, listen: false).fetchMyLeaves(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the LeaveProvider for data and loading state
    final leaveProvider = Provider.of<LeaveProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Status'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: leaveProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                // Add pull-to-refresh
                final token = Provider.of<AuthProvider>(context, listen: false).token;
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
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFC62828)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Track your leave applications and history',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
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
                        _buildStatCard('Approved', leaveProvider.approvedCount.toString(), Colors.green),
                        _buildStatCard('Pending', leaveProvider.pendingCount.toString(), Colors.orange),
                        _buildStatCard('Rejected', leaveProvider.rejectedCount.toString(), Colors.red),
                        _buildStatCard('Total Days', leaveProvider.totalDays.toString(), Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Leave History Section
                    Card(
                      elevation: 2.0,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
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
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 16),
                            // Search Bar
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Search leave applications...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(color: Colors.grey),
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
                  ],
                ),
              ),
            ),
    );
  }

  // Helper for the top Stat Cards
  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for the list items
  Widget _buildLeaveTile(Map<String, dynamic> leave) {
    // --- FIX IS HERE ---
    // 1. Get the string
    String leaveType = leave['leaveType']?.toString() ?? 'Leave';
    
    // 2. Manually capitalize it
    if (leaveType.isNotEmpty) {
      leaveType = leaveType[0].toUpperCase() + leaveType.substring(1).toLowerCase();
    }
    // --- END FIX ---

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!)
      ),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          leaveType, // 3. Use the corrected string
          style: const TextStyle(fontWeight: FontWeight.bold), // 4. Removed 'textTransform'
        ),
        subtitle: Text(
          '${leave['fromDate'] ?? 'N/A'} to ${leave['toDate'] ?? 'N/A'} (${leave['days'] ?? 0} days)',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusChip(leave['finalStatus']?.toString() ?? 'Pending'),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
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