import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

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
              fontFamily: 'PoetsenOne',
              color: Colors.black,
            ),
          ),
        ),
      );
    }

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFFFC727),
      appBar: AppBar(
        title: const Text(
          'My Account',
          style: TextStyle(
            fontFamily: 'PoetsenOne',
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFFC727),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: userDoc.get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading user data',
                style: TextStyle(fontFamily: 'PoetsenOne'),
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
                style: TextStyle(fontFamily: 'PoetsenOne'),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.black,
                  child: Icon(
                    Icons.person,
                    size: 80,
                    color: Color(0xFFFFC727),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  data['username'] ?? 'No Username',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PoetsenOne',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),

                _buildInfoTile(Icons.person, 'Full Name', data['fullname'] ?? 'No Fullname'),
                const SizedBox(height: 12),
                _buildInfoTile(Icons.email, 'Email', data['email'] ?? user.email ?? 'No Email'),
                const SizedBox(height: 12),
                _buildInfoTile(Icons.lock, 'Password', data['password'] ?? 'No Password'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.black),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label:',
                style: const TextStyle(
                  fontFamily: 'PoetsenOne',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'PoetsenOne',
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
