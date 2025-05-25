import 'package:einventorycomputer/models/user.dart';
import 'package:einventorycomputer/modules/authentication/authenticate.dart';
import 'package:einventorycomputer/modules/home/screen/screen.dart';
import 'package:einventorycomputer/modules/home/screen/test.dart';
import 'package:einventorycomputer/modules/home/screen/wrapper.dart';
import 'package:einventorycomputer/services/auth.dart';
import 'package:einventorycomputer/models/user.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // final PageController pageController = PageController();

    // return MaterialApp(
    //   theme: ThemeData(
    //     useMaterial3: true,
    //     fontFamily: 'Poppins',
    //     textTheme: const TextTheme(
    //       bodyLarge: TextStyle(fontFamily: 'Poppins'),
    //       bodyMedium: TextStyle(fontFamily: 'Poppins'),
    //       displayLarge: TextStyle(fontFamily: 'Poppins'), 
    //       displayMedium: TextStyle(fontFamily: 'Poppins'),
    //     ),
    //   ),

    //   home: Authenticate(),

    //   // home: RevenueScreen(),

    // );

    return StreamProvider<MyUser?>.value(
      value: AuthService().user,
      initialData: null,
      child: MaterialApp(
      home: Wrapper(),
      ),
    );

  }
}
