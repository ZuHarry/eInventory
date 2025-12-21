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

  // sign in with email & password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      // Check if email is verified
      if (user != null && !user.emailVerified) {
        // Sign out the user immediately if email is not verified
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email before signing in.',
        );
      }

      return _userFormFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

 Future registerWithEmailAndPassword(String fullname, String username, String email, String password, String telephone, String staffType, String staffId, String department) async {
  try {
    UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    User? user = result.user;

    await sendEmailVerification();

    // ✅ Now passing department parameter (8th parameter)
    await DatabaseService(uid: user!.uid).registerUserData(
      fullname, 
      username, 
      email, 
      password, 
      telephone, 
      staffType, 
      staffId,
      department  // ✅ Added here
    );

    return _userFormFirebaseUser(user);
  } catch (e) {
    print(e.toString());
    return null;
  }
}

   // Password reset method
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw e;
    }
  }
  

  // Check if current user's email is verified
  bool get isEmailVerified {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Get current user
  User? get currentUser {
    return _auth.currentUser;
  }

  // Send or resend verification email with better error handling
  // Future<bool> sendEmailVerification() async {
  //   try {
  //     User? user = _auth.currentUser;
  //     if (user != null && !user.emailVerified) {
  //       await user.sendEmailVerification();
  //       return true;
  //     }
  //     return false;
  //   } catch (e) {
  //     print('Error sending verification email: ${e.toString()}');
  //     return false;
  //   }
  // }

  Future<void> sendEmailVerification() async {
  try {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    } else if (user == null) {
      throw Exception('No user logged in');
    }
  } catch (e) {
    print('Error sending verification email: $e');
    rethrow;
  }
}

//   Future<void> sendEmailVerification() async {
//   User? user = _auth.currentUser;
//   if (user != null && !user.emailVerified) {
//     await user.sendEmailVerification();
//   }
// }

  // Reload user to check verification status
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      print('Error reloading user: ${e.toString()}');
    }
  }

  // Check if email is verified after reloading
  Future<bool> checkEmailVerified() async {
    await reloadUser();
    return isEmailVerified;
  }

  // sign out
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}