import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    
    // User needs to be created before calling this
    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    
    if (!isEmailVerified) {
      sendVerificationEmail();
      
      // Set up timer to check verification status periodically
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    // Call after email verification
    await FirebaseAuth.instance.currentUser!.reload();
    
    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });
    
    if (isEmailVerified) {
      timer?.cancel();
      // No manual navigation needed - StreamProvider will handle this automatically
      // Just show a success message or let the auth wrapper handle navigation
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
      
      setState(() => canResendEmail = false);
      await Future.delayed(const Duration(seconds: 5));
      setState(() => canResendEmail = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending verification email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC727),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC727),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 100, color: Colors.black),
              const SizedBox(height: 24),
              const Text(
                'Verification Email Sent!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SansRegular',
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We have sent a verification email to:\n${FirebaseAuth.instance.currentUser!.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'SansRegular',
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please check your email and click the verification link before proceeding.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'SansRegular',
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: canResendEmail ? sendVerificationEmail : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  canResendEmail ? 'Resend Email' : 'Email Sent',
                  style: const TextStyle(
                    fontFamily: 'SansRegular',
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => checkEmailVerified(),
                child: const Text(
                  'I have verified my email',
                  style: TextStyle(
                    fontFamily: 'SansRegular',
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'SansRegular',
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}