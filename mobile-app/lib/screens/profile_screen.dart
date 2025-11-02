// lib/screens/profile_screen.dart

import 'dart:convert'; // Needed for Base64 image
import 'dart:ui'; // <-- ADDED for ImageFilter
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
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  
  bool _isDataLoaded = false;

  // --- MODIFIED initState ---
  // We just use initState to trigger the fetch if data is missing
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.profileData == null) {
        authProvider.fetchProfile();
      }
    });
  }

  // --- REMOVED didChangeDependencies ---
  // We no longer need this method, the logic is moving to build()

  @override
  void dispose() {
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
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black87),
      filled: true,
      fillColor: Colors.white.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This makes the build() method re-run when data arrives
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.profileData;
    
    // --- THIS IS THE FIX ---
    // We populate the controllers here. When the provider notifies
    // that data has arrived, this build method runs again,
    // `profile` will NOT be null, and the controllers will be filled.
    if (profile != null && !_isDataLoaded) {
      _nameController.text = profile['name'] ?? '';
      _phoneController.text = profile['phone'] ?? '';
      _departmentController.text = profile['department'] ?? '';
      _isDataLoaded = true;
    }
    // --- END FIX ---
    
    final String? base64Image = profile?['profile_image'];
    
    Widget profileAvatar;
    
    if (base64Image != null && base64Image.isNotEmpty) {
      final imageBytes = base64Decode(base64Image.split(',').last);
      profileAvatar = CircleAvatar(
        radius: 60,
        backgroundImage: MemoryImage(imageBytes),
      );
    } else {
      profileAvatar = const CircleAvatar(
        radius: 60,
        backgroundColor: Colors.white70,
        child: Icon(Icons.person, size: 60, color: Colors.black54),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: authProvider.isLoading ? null : _saveProfile,
          ),
        ],
      ),
      
      body: Stack(
        children: [
          // 1. The Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/back1.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. The Content
          SafeArea(
            // Use a simpler loading check
            child: (authProvider.isLoading && !_isDataLoaded)
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                profileAvatar,
                                TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Image upload coming soon!')),
                                    );
                                  },
                                  child: const Text(
                                    'Change Photo',
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                TextFormField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: _buildInputDecoration('Full Name'),
                                  validator: (value) =>
                                      value!.isEmpty ? 'Name cannot be empty' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _phoneController, // This will now have text
                                  style: const TextStyle(color: Colors.black),
                                  decoration: _buildInputDecoration('Phone Number'),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _departmentController, // This will now have text
                                  style: const TextStyle(color: Colors.black),
                                  decoration: _buildInputDecoration('Department'),
                                ),
                                const SizedBox(height: 40),
                                if (authProvider.isLoading)
                                  CircularProgressIndicator(color: Colors.red.shade700),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}