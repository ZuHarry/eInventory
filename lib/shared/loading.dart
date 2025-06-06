import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: SpinKitChasingDots(
          color: Color(0xFFFFC727),
          size: 100.0,
        ), 
      ),
    );
  }
}