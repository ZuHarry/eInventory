// email_verification.dart
import 'package:flutter/material.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC727),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.email, size: 100, color: Colors.black),
              SizedBox(height: 24),
              Text(
                'Verification Email Sent!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SansRegular',
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Please check your email and verify your account before signing in.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'SansRegular',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
