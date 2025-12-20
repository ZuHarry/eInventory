import 'package:flutter/material.dart';
import 'view_brand.dart'; // Import the view_brand.dart file
import 'user_list.dart';

class DiscoverPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212529),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFFFFC727),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Discover',
          style: TextStyle(
            fontFamily: 'SansRegular',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFC727),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explore',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212529),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse through all available data',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 14,
                color: Color(0xFF6C757D),
              ),
            ),
            const SizedBox(height: 24),
            
            // View All Brands Button
            _buildDiscoverCard(
              context: context,
              title: 'View All Brands',
              subtitle: 'Browse all device brands',
              icon: Icons.business_rounded,
              color: const Color(0xFFFFC727),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewBrandPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            
            // View All Users Button
            _buildDiscoverCard(
              context: context,
              title: 'View All Users',
              subtitle: 'Browse all system users',
              icon: Icons.people_rounded,
              color: const Color(0xFF007BFF),
              onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllUsersPage(),
                ),
              );
            },
            ),
            const SizedBox(height: 12),
            
            // View All Buildings Button
            _buildDiscoverCard(
              context: context,
              title: 'View All Buildings',
              subtitle: 'Browse all buildings',
              icon: Icons.apartment_rounded,
              color: const Color(0xFF28A745),
              onTap: () {
                // TODO: Navigate to All Buildings page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('View All Buildings - Coming Soon'),
                    backgroundColor: Color(0xFF6C757D),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
          child: Row(
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212529),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 13,
                        color: Color(0xFF6C757D),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}