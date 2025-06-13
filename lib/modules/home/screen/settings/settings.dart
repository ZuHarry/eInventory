import 'package:flutter/material.dart';
import 'package:einventorycomputer/services/auth.dart';
import 'package:einventorycomputer/modules/home/screen/user/account.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Match the background color
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          _buildSettingsButton(
            Icons.person,
            'Account Settings',
            onTap: () {
              // Navigate to Account page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsButton(
            Icons.format_paint,
            'Appearance & Styles',
            onTap: () {
              // Show coming soon dialog
              _showComingSoonDialog(context, 'Appearance & Styles');
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsButton(
            Icons.notifications,
            'Notifications',
            onTap: () {
              // Show coming soon dialog
              _showComingSoonDialog(context, 'Notifications');
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsButton(
            Icons.info_outline,
            'About App',
            onTap: () {
              // Show about dialog
              _showAboutDialog(context);
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsButton(
            Icons.logout,
            'Log Out',
            onTap: () async {
              // Show confirmation dialog
              final shouldLogout = await _showLogoutConfirmationDialog(context);
              if (shouldLogout == true) {
                await _auth.signOut();
                // The auth state listener in your app should handle navigation to login
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(IconData icon, String label, {VoidCallback? onTap}) {
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
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
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF6C757D),
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC727).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFFFFC727),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Coming Soon',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            '$feature feature will be available soon!',
            style: const TextStyle(
              fontFamily: 'SansRegular',
              fontSize: 16,
              color: Color(0xFF6C757D),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Color(0xFFFFC727),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC727).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Color(0xFFFFC727),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'E-Inventory',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212529),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'E-Inventory is a comprehensive inventory management system designed to help you track and manage devices efficiently.',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 14,
                  color: Color(0xFF6C757D),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '© 2024 E-Inventory. All rights reserved.',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 12,
                  color: Color(0xFF6C757D),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Color(0xFFFFC727),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showLogoutConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Log Out',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              fontFamily: 'SansRegular',
              fontSize: 16,
              color: Color(0xFF6C757D),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Color(0xFF6C757D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}