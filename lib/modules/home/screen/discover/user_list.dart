import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllUsersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212529),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFFFFC727)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Users',
          style: TextStyle(
            fontFamily: 'SansRegular',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFC727),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('fullname')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC727)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading users',
                style: const TextStyle(
                  fontFamily: 'SansRegular',
                  color: Color(0xFF6C757D),
                  fontSize: 14,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 64,
                    color: const Color(0xFFDEE2E6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: const TextStyle(
                      fontFamily: 'SansRegular',
                      color: Color(0xFF6C757D),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              return _buildUserCard(userData);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and staff type badge
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC727).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(user['fullname'] ?? 'Unknown'),
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212529),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['fullname'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontFamily: 'SansRegular',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212529),
                        ),
                      ),
                      if (user['staffId'] != null)
                        Text(
                          'ID: ${user['staffId']}',
                          style: const TextStyle(
                            fontFamily: 'SansRegular',
                            fontSize: 12,
                            color: Color(0xFF6C757D),
                          ),
                        ),
                    ],
                  ),
                ),
                if (user['staffType'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStaffTypeColor(user['staffType']),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      user['staffType'],
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFDEE2E6)),
            const SizedBox(height: 16),

            // Contact Information
            if (user['email'] != null) ...[
              _buildInfoRow(
                Icons.email_rounded,
                'Email',
                user['email'],
              ),
              const SizedBox(height: 12),
            ],
            if (user['telephoneNumber'] != null) ...[
              _buildInfoRow(
                Icons.phone_rounded,
                'Phone',
                user['telephoneNumber'],
              ),
              const SizedBox(height: 12),
            ],

            // Additional Info Row
            Row(
              children: [
                if (user['staffType'] != null) ...[
                  Expanded(
                    child: _buildInfoChip(
                      Icons.work_rounded,
                      user['staffType'],
                    ),
                  ),
                ],
                if (user['staffId'] != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.badge_rounded,
                      user['staffId'],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, dynamic value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF6C757D),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 11,
                  color: Color(0xFF6C757D),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value?.toString() ?? 'N/A',
                style: const TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF212529),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFDEE2E6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF6C757D),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF212529),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Color _getStaffTypeColor(String? staffType) {
    switch (staffType?.toLowerCase()) {
      case 'admin':
        return const Color(0xFFDC3545);
      case 'manager':
        return const Color(0xFF007BFF);
      case 'technician':
        return const Color(0xFF28A745);
      case 'staff':
        return const Color(0xFF6C757D);
      default:
        return const Color(0xFF6C757D);
    }
  }
}