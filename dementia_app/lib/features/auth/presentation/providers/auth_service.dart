import 'package:dementia_app/features/auth/domain/entities/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  Future<UserModel?> getCurrentUser() async {
    User? firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
    }
    return null;
  }

  Future<UserModel> login(String email, String password) async {
    UserCredential userCredential =
        await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;

    DocumentSnapshot snapshot =
        await _firestore.collection('users').doc(user?.uid).get();
    UserModel loggedInUser =
        UserModel.fromMap(snapshot.data() as Map<String, dynamic>);

    await _secureStorage.write(key: 'uid', value: user?.uid);

    return loggedInUser;
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _secureStorage.delete(key: 'uid');
  }

  Future<bool> isLoggedIn() async {
    User? user = _firebaseAuth.currentUser;
    return user != null;
  }
}
