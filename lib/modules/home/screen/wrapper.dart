import 'package:einventorycomputer/models/user.dart';
import 'package:einventorycomputer/modules/authentication/authenticate.dart';
import 'package:einventorycomputer/modules/home/main/screen.dart';
import 'package:einventorycomputer/modules/home/screen/splash_screen.dart';
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
    // Show splash screen for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
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

    if (user == null) {
      return Authenticate();
    } else {
      return _showSplash ? const SplashScreenPage() : ScreenPage();
    }
  }
}
