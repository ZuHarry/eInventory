import 'package:flutter/material.dart';

class EInventoryBlankPage extends StatelessWidget {
  const EInventoryBlankPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon/Logo Container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF81D4FA),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF81D4FA).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 64,
                color: Color(0xFF212529),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App Name
            const Text(
              'e-Inventory',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212529),
                fontFamily: 'SansRegular',
                letterSpacing: -0.5,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Subtitle
            const Text(
              'Computer Management System',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6C757D),
                fontFamily: 'SansRegular',
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Decorative dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(const Color(0xFF81D4FA)),
                const SizedBox(width: 8),
                _buildDot(const Color(0xFF212529)),
                const SizedBox(width: 8),
                _buildDot(const Color(0xFF6C757D)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}