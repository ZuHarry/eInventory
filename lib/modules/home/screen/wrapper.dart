import 'package:einventorycomputer/models/user.dart';
import 'package:einventorycomputer/modules/authentication/authenticate.dart';
import 'package:einventorycomputer/modules/authentication/verify_email.dart';
import 'package:einventorycomputer/modules/home/main/screen.dart';
import 'package:einventorycomputer/modules/home/screen/splash_screen.dart';
import 'package:einventorycomputer/services/ping.dart'; // Add this import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatefulWidget {
  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> with WidgetsBindingObserver {
  bool _showSplash = true;
  final DevicePingService _pingService = DevicePingService();
  bool _isPingingStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pingService.stopPeriodicPing();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - restart pinging if user is authenticated
        if (_isPingingStarted) {
          _pingService.startPeriodicPing(interval: const Duration(seconds: 30));
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App went to background - optionally stop pinging to save battery
        // Uncomment the line below if you want to stop pinging when app is not active
        // _pingService.stopPeriodicPing();
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        _pingService.stopPeriodicPing();
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state if needed
        break;
    }
  }

  void _startPingingIfNeeded() {
    if (!_isPingingStarted) {
      _isPingingStarted = true;
      _pingService.startPeriodicPing(interval: const Duration(seconds: 30));
      
      // Optional: Do an initial ping immediately
      _pingService.pingAllDevices();
      
      print('Device pinging started');
    }
  }

  void _stopPinging() {
    if (_isPingingStarted) {
      _isPingingStarted = false;
      _pingService.stopPeriodicPing();
      print('Device pinging stopped');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);

    if (_showSplash) {
      return const SplashScreenPage();
    }

    if (user == null) {
      // User is not authenticated - stop pinging if it was running
      _stopPinging();
      return Authenticate();
    } else {
      // User is authenticated - start pinging
      _startPingingIfNeeded();
      
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
            return ScreenPage();
          } else {
            // User is logged in and email is verified
            return ScreenPage();
          }
        },
      );
    }
  }
}