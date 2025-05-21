import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'No user is signed in',
          style: TextStyle(fontSize: 24),
        ),
      );
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: FutureBuilder<DocumentSnapshot>(
        future: userDoc.get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading user data'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text('User data not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Account icon centered
                const Icon(
                  Icons.account_circle,
                  size: 120,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 24),

                // User info
                Text(
                  data['username'] ?? 'No Username',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    const Icon(Icons.email),
                    const SizedBox(width: 8),
                    Text(data['email'] ?? user.email ?? 'No Email'),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(Icons.lock),
                    const SizedBox(width: 8),
                    Text(data['password'] ?? 'No Password'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
