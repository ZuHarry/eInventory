import 'package:flutter/material.dart';

class GetStarted extends StatelessWidget {
  final VoidCallback onGetStarted;
  const GetStarted({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF81D4FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text(
                'Welcome to E-Inventory',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Manage inventory with ease.\nSimple, fast, and efficient.',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
