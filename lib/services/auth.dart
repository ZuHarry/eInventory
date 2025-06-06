import 'package:einventorycomputer/models/user.dart';
import 'package:einventorycomputer/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

   // Create user obj based on Firebase User
  MyUser? _userFormFirebaseUser(User? user) {
    return user != null ? MyUser(uid: user.uid) : null;
  }

  // Auth change user stream
  Stream<MyUser?> get user {
    return _auth.authStateChanges().map(_userFormFirebaseUser);
  }

  // sign in anon
  Future signInAnon() async {

    try {
    UserCredential result = await _auth.signInAnonymously();
    User? user = result.user;
    return _userFormFirebaseUser(user!);
  } catch (e) {
    print(e.toString());
    return null;
  }
  }

  // sign is with email & password
  Future signInWithEmailAndPassword(String email, String password) async {
    try{
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      return _userFormFirebaseUser(user);
    }catch(e){
      print(e.toString());
      return null;

    }
  }


  // register with email & password
  Future registerWithEmailAndPassword(String fullname, String username, String email, String password) async {
    try{
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      // create a new document for the user with the uid
      await DatabaseService(uid: user!.uid).registerUserData(fullname, username, email, password);
      return _userFormFirebaseUser(user);
    }catch(e){
      print(e.toString());
      return null;

    }
  }

  // sign out
  Future signOut() async {
    try{
      return await _auth.signOut();
    }catch(e){
      print(e.toString());
      return null;
    }
  }
}