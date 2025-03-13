import 'package:dementia_app/features/auth/domain/entities/user_model.dart';
import 'package:dementia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Sign up with email and password
  @override
  Future<UserModel> signUpWithEmail(
    String email,
    String password,
    String firstName,
    String lastName,
    String dob,
    String gender,
  ) async {
    UserCredential userCredential =
        await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;

    // Create UserModel and store it in Firestore
    UserModel newUser = UserModel(
      uid: user?.uid ?? '',
      email: email,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dob,
      gender: gender,
      profilePicUrl: '',
    );

    // Save user data to Firestore
    await _firestore.collection('users').doc(user?.uid).set(newUser.toMap());

    // Save user UID to secure storage for session management
    await _secureStorage.write(key: 'uid', value: user?.uid);

    return newUser;
  }

  // Login with email and password
  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    UserCredential userCredential =
        await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;

    // Fetch additional user data from Firestore
    DocumentSnapshot snapshot =
        await _firestore.collection('users').doc(user?.uid).get();
    UserModel loggedInUser =
        UserModel.fromMap(snapshot.data() as Map<String, dynamic>);

    // Save user UID to secure storage for session management
    await _secureStorage.write(key: 'uid', value: user?.uid);

    return loggedInUser;
  }

  // Fetch user data from secure storage
  @override
  Future<UserModel?> getUserFromSecureStorage() async {
    String? uid = await _secureStorage.read(key: 'uid');
    if (uid != null) {
      DocumentSnapshot snapshot =
          await _firestore.collection('users').doc(uid).get();
      return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Logout and clear the secure storage
  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _secureStorage.delete(key: 'uid');
  }
}
