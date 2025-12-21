import 'package:einventorycomputer/models/user.dart';
import 'package:einventorycomputer/modules/authentication/authenticate.dart';
import 'package:einventorycomputer/modules/home//screen/wrapper.dart';  // Fixed path
import 'package:einventorycomputer/modules/home//screen/blank.dart';
import 'package:einventorycomputer/services/auth.dart';
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
    return StreamProvider<MyUser?>.value(
      value: AuthService().user,
      initialData: null,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'SansRegular',
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontFamily: 'SansRegular'),
            bodyMedium: TextStyle(fontFamily: 'SansRegular'),
            displayLarge: TextStyle(fontFamily: 'SansRegular'), 
            displayMedium: TextStyle(fontFamily: 'SansRegular'),
          ),
        ),
        home: Wrapper(),
      ),
    );
  }
}