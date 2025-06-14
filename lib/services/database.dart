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

  Future registerUserData(String fullname, String username, String email, String password, String telephone, String staffType, String staffId) async {
    return await accountCollection.doc(uid).set({
      'uid' : uid,
      'fullname' : fullname,
      'username' : username,
      'email': email,
      'password' : password,
      'telephone': telephone,
      'staffType': staffType,
      'staffId': staffId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update user account data
  Future updateAccountData(String fullname, String username, String email, String telephone, String staffType, String staffId, {String? password}) async {
    Map<String, dynamic> updateData = {
      'fullname': fullname,
      'username': username,
      'email': email,
      'telephone': telephone,
      'staffType': staffType,
      'staffId': staffId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Only include password if it's provided
    if (password != null && password.isNotEmpty) {
      updateData['password'] = password;
    }

    return await accountCollection.doc(uid).update(updateData);
  }

  // Get user data
  Future<DocumentSnapshot> getUserData() async {
    return await accountCollection.doc(uid).get();
  }

  // Check if staff ID already exists (useful for validation)
  Future<bool> isStaffIdTaken(String staffId) async {
    final QuerySnapshot result = await accountCollection
        .where('staffId', isEqualTo: staffId)
        .limit(1)
        .get();
    return result.docs.isNotEmpty;
  }

  // Get user by staff ID
  Future<QuerySnapshot> getUserByStaffId(String staffId) async {
    return await accountCollection
        .where('staffId', isEqualTo: staffId)
        .limit(1)
        .get();
  }

  // get brews stream
  Stream<QuerySnapshot?> get brews {
    return brewCollection.snapshots();
  }

  // Stream<QuerySnapshot<Object?>> get brews {
  //   return FirebaseFirestore.instance.collection('brews').snapshots();
  // }
}