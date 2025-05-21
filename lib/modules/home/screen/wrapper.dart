import 'package:einventorycomputer/models/user.dart';
import 'package:einventorycomputer/modules/authentication/authenticate.dart';
import 'package:einventorycomputer/modules/home/screen/screen.dart';
import 'package:einventorycomputer/modules/home/screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget{
  @override
  Widget build(BuildContext context){

    final user = Provider.of<MyUser?>(context);
   
    if (user == null){
      return Authenticate();
    } else {
      return ScreenPage();
    }
    
  }
}