import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Match the background color
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          _buildSettingsButton(Icons.person, 'Account Settings'),
          const SizedBox(height: 12),
          _buildSettingsButton(Icons.format_paint, 'Appearance & Styles'),
          const SizedBox(height: 12),
          _buildSettingsButton(Icons.notifications, 'Notifications'),
          const SizedBox(height: 12),
          _buildSettingsButton(Icons.info_outline, 'About App'),
          const SizedBox(height: 12),
          _buildSettingsButton(Icons.logout, 'Log Out'),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Set button background to white
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFFFC727)), // Yellow icon color
        title: Text(
          label,
          style: const TextStyle(
            fontFamily: 'SansRegular',
            fontSize: 18,
            color: Color(0xFF212529), // Dark text color
          ),
        ),
        onTap: () {
          // Dummy onTap - you can add navigation or dialogs later
        },
      ),
    );
  }
}