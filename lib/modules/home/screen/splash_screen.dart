import 'dart:async';
import 'package:flutter/material.dart';
import 'package:einventorycomputer/modules/authentication/authenticate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Trigger fade-in animation
    Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _opacity = 1.0;
      });
    });

    // Navigate to Authenticate page after 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => Authenticate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC727),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/checklists.png', width: 120),
            const SizedBox(height: 24),
            AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 700),
              child: Column(
                children: const [
                  Text(
                    'e-Inventory',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF153B6D),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Smart Inventory Management',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
