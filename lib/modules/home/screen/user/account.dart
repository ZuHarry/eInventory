import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'modify_account.dart'; // Import the modify account page

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // Add a key to force rebuild of FutureBuilder
  int _refreshKey = 0;

  void _refreshData() {
    setState(() {
      _refreshKey++;
    });
  }

  Future<void> _navigateToModifyAccount() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModifyAccountPage(),
      ),
    );
    
    // Refresh data when returning from modify page
    if (result == true || result == null) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No user is signed in',
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'SansRegular',
              color: Colors.black,
            ),
          ),
        ),
      );
    }

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Modify button in app bar
          IconButton(
            onPressed: _navigateToModifyAccount,
            icon: const Icon(
              Icons.edit,
              color: Colors.black,
            ),
            tooltip: 'Modify Account',
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        key: ValueKey(_refreshKey), // This forces rebuild when key changes
        future: userDoc.get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading user data',
                style: TextStyle(fontFamily: 'SansRegular'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(
              child: Text(
                'User data not found',
                style: TextStyle(fontFamily: 'SansRegular'),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final profileImageUrl = data['profileImageUrl'] as String?;

          return RefreshIndicator(
            onRefresh: () async {
              _refreshData();
              // Wait a bit for the refresh to complete
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(), // Enables pull-to-refresh
                child: Column(
                  children: [
                    // Profile Image with fallback
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFC727),
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.black,
                        backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        child: profileImageUrl == null || profileImageUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 80,
                                color: Color(0xFFFFC727),
                              )
                            : null,
                        onBackgroundImageError: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? (exception, stackTrace) {
                                // This will be called if the image fails to load
                                // The fallback icon will be shown automatically
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      data['username'] ?? 'No Username',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SansRegular',
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Staff type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStaffTypeColor(data['staffType']),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data['staffType'] ?? 'No Staff Type',
                        style: const TextStyle(
                          fontFamily: 'SansRegular',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildInfoTile(Icons.person, 'Full Name', data['fullname'] ?? 'No Fullname'),
                    const SizedBox(height: 16),
                    _buildInfoTile(Icons.email, 'Email', data['email'] ?? user.email ?? 'No Email'),
                    const SizedBox(height: 16),
                    _buildInfoTile(Icons.phone, 'Telephone', data['telephone'] ?? 'No Phone Number'),
                    const SizedBox(height: 16),
                    _buildInfoTile(Icons.badge, 'Staff ID', data['staffId'] ?? 'No Staff ID'),
                    const SizedBox(height: 16),
                    _buildInfoTile(Icons.work, 'Staff Type', data['staffType'] ?? 'No Staff Type'),
                    
                    const SizedBox(height: 32),
                    
                    // Modify Account Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToModifyAccount,
                        icon: const Icon(Icons.edit, color: Colors.black),
                        label: const Text(
                          'Modify Account',
                          style: TextStyle(
                            fontFamily: 'SansRegular',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC727),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStaffTypeColor(String? staffType) {
    switch (staffType) {
      case 'Staff':
        return Colors.blue;
      case 'Lecturer':
        return Colors.green;
      case 'Technician':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC727),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'SansRegular',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'SansRegular',
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}