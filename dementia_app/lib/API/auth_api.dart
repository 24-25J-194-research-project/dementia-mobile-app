import 'package:dementia_app/Shared/constants.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthApi {
  final supabase = Supabase.instance.client;

  Future<void> signInWithGoogle() async {
    final webClientId = Constants.webClientID;
    final iosClientId = Constants.iosClientID;

    await supabase.auth.signOut();
    await GoogleSignIn().signOut();

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
      scopes: ['email', 'profile'],
    );

    try {
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) throw 'Google sign in canceled';

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) throw 'No Access Token found.';
      if (idToken == null) throw 'No ID Token found.';

      //store user metadata in Supabase
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      //update user metadata after sign in
      if (googleUser.photoUrl != null) {
        await supabase.auth.updateUser(
          UserAttributes(
            data: {
              'avatar_url': googleUser.photoUrl,
              'name': googleUser.displayName
            }
          )
        );
      }
      
    } catch (error) {
      throw 'Failed to sign in:$error';
    }
  }
}