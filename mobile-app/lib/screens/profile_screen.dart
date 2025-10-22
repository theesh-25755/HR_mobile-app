// lib/screens/profile_screen.dart

import 'dart:convert'; // Needed for Base64 image
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Create controllers to manage the text fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  
  bool _isDataLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Load the data into the controllers one time
    if (!_isDataLoaded) {
      final authProvider = Provider.of<AuthProvider>(context);
      
      // Make sure profileData is not null before accessing it
      if (authProvider.profileData != null) {
        _nameController.text = authProvider.profileData!['name'] ?? '';
        _phoneController.text = authProvider.profileData!['phone'] ?? '';
        _departmentController.text = authProvider.profileData!['department'] ?? '';
        _isDataLoaded = true;
      } else {
        // If data isn't loaded yet, fetch it
        // This handles navigating directly to the profile page on a fresh app load
        authProvider.fetchProfile();
      }
    }
  }

  @override
  void dispose() {
    // Clean up the controllers
    _nameController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final dataToSave = {
      "name": _nameController.text,
      "phone": _phoneController.text,
      "department": _departmentController.text,
    };

    try {
      await Provider.of<AuthProvider>(context, listen: false).saveProfile(dataToSave);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile Updated!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Go back to home screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the provider
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.profileData;
    
    // Get the base64 profile image string
    final String? base64Image = profile?['profile_image'];
    
    Widget profileAvatar;
    
    if (base64Image != null && base64Image.isNotEmpty) {
      // Decode the base64 string
      // We split on ',' in case it's a data URL like 'data:image/png;base64,....'
      final imageBytes = base64Decode(base64Image.split(',').last);
      profileAvatar = CircleAvatar(
        radius: 60,
        backgroundImage: MemoryImage(imageBytes),
      );
    } else {
      // Default avatar
      profileAvatar = const CircleAvatar(
        radius: 60,
        child: Icon(Icons.person, size: 60),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          // Save Button
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: authProvider.isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: (authProvider.isLoading && !_isDataLoaded) || profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    profileAvatar,
                    TextButton(
                      onPressed: () {
                        // TODO: We will add image upload logic here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Image upload coming soon!')),
                        );
                      },
                      child: const Text('Change Photo'),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Name cannot be empty' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(labelText: 'Department'),
                    ),
                    const SizedBox(height: 40),
                    if (authProvider.isLoading)
                      const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
    );
  }
}