import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Pages/sign_in_page.dart';

class AuthService {
  final supabase = Supabase.instance.client;
  
  //singleton pattern
  static final AuthService _instance = AuthService._internal();
  
  factory AuthService() => _instance;
  
  AuthService._internal();
  
  //sign out method
  Future<void> signOut(BuildContext context) async {
    try {
      //sign out from Supabase
      await supabase.auth.signOut();
      
      //sign out from Google
      await GoogleSignIn().signOut();
      
      if (context.mounted) {
        //navigate to sign in page and clear all routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $error'),
          ),
        );
      }
    }
  }
}