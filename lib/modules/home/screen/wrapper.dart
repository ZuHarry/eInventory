import 'package:einventorycomputer/models/user.dart';
import 'package:einventorycomputer/modules/authentication/authenticate.dart';
import 'package:einventorycomputer/modules/authentication/verify_email.dart';
import 'package:einventorycomputer/modules/home/main/staff.dart';
import 'package:einventorycomputer/modules/home/main/technician.dart'; // Add admin screen import
import 'package:einventorycomputer/modules/home/screen/splash_screen.dart';
import 'package:einventorycomputer/services/ping.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        if (_isPingingStarted) {
          _pingService.startPeriodicPing(interval: const Duration(seconds: 30));
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        _pingService.stopPeriodicPing();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _startPingingIfNeeded() {
    if (!_isPingingStarted) {
      _isPingingStarted = true;
      _pingService.startPeriodicPing(interval: const Duration(seconds: 30));
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

  Future<String> _getUserStaffType(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (userDoc.exists) {
        return userDoc.get('staffType') ?? 'Staff'; // Default to 'Staff' if staffType field doesn't exist
      }
      return 'Staff';
    } catch (e) {
      print('Error fetching user staffType: $e');
      return 'Staff';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<MyUser?>(context);

    if (_showSplash) {
      return const SplashScreenPage();
    }

    if (user == null) {
      _stopPinging();
      return Authenticate();
    } else {
      _startPingingIfNeeded();
      
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
          
          if (firebaseUser != null) {
            // Check user staffType from Firestore
            return FutureBuilder<String>(
              future: _getUserStaffType(firebaseUser.uid),
              builder: (context, staffTypeSnapshot) {
                if (staffTypeSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final staffType = staffTypeSnapshot.data ?? 'Staff';
                
                // Route based on staffType
                // Only Technician goes to AdminScreen, others go to regular ScreenPage
                if (staffType == 'Technician') {
                  return AdminScreen(); // Admin/Technician page
                } else {
                  // Staff or Lecturer go to regular user page
                  return ScreenPage(); 
                }
              },
            );
          } else {
            return Authenticate();
          }
        },
      );
    }
  }
}