import 'package:einventorycomputer/models/user.dart';
import 'package:einventorycomputer/modules/authentication/authenticate.dart';
import 'package:einventorycomputer/modules/authentication/verify_email.dart';
import 'package:einventorycomputer/modules/home/main/screen.dart';
import 'package:einventorycomputer/modules/home/screen/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatefulWidget {
  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Show splash screen for 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);

    if (_showSplash) {
      return const SplashScreenPage();
    }

    if (user == null) {
      return Authenticate();
    } else {
      // Use StreamBuilder to listen to auth state changes
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final firebaseUser = snapshot.data;
          
          if (firebaseUser != null && !firebaseUser.emailVerified) {
            // User is logged in but email is not verified
            return const VerifyEmail();
          } else {
            // User is logged in and email is verified
            return ScreenPage();
          }
        },
      );
    }
  }
}