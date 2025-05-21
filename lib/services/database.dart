import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {

  final String? uid;
  DatabaseService({ this.uid });

  // collection reference
  final CollectionReference brewCollection = FirebaseFirestore.instance.collection("brews");

  // collection reference
  final CollectionReference accountCollection = FirebaseFirestore.instance.collection("users");


  Future updateUserData(String sugars, String name, int strength) async {
    return await brewCollection.doc(uid).set({
      'sugars': sugars,
      'name': name,
      'strength': strength,
    });
  }

  Future registerUserData(String fullname, String username, String email, String password) async {
    return await accountCollection.doc(uid).set({
      'uid' : uid,
      'fullname' : fullname,
      'username' : username,
      'email': email,
      'password' :password,
    });
  }

  // get brews stream
  Stream<QuerySnapshot?> get brews {
    return brewCollection.snapshots();
  }

  // Stream<QuerySnapshot<Object?>> get brews {
  //   return FirebaseFirestore.instance.collection('brews').snapshots();
  // }

}