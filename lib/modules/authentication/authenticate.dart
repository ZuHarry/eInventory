import 'package:einventorycomputer/modules/authentication/get_started.dart';
import 'package:einventorycomputer/modules/authentication/sign_in.dart';
import 'package:einventorycomputer/modules/authentication/sign_up.dart';
import 'package:flutter/material.dart';

class Authenticate extends StatefulWidget {
  @override
  _AuthenticateState createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool hasStarted = false;
  bool showSignIn = true;

  void onGetStarted() {
    setState(() {
      hasStarted = true;
    });
  }

  void toggleView() {
    setState(() => showSignIn = !showSignIn);
  }

  @override
  Widget build(BuildContext context) {
    if (!hasStarted) {
      return GetStarted(onGetStarted: onGetStarted);
    } else if (showSignIn) {
      return SignIn(toggleView: toggleView);
    } else {
      return SignUp(toggleView: toggleView);
    }
  }
}
