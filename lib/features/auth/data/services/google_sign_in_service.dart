import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service managing native Google Sign-In with Play Services.
/// Configured with verified TrueLern Web Client ID for Android ID token minting.
class GoogleSignInService {
  GoogleSignInService({GoogleSignIn? googleSignIn})
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            serverClientId: '765360296728-9djdevn7k3vle3k4hjc0naq5k6el4s9e.apps.googleusercontent.com',
            scopes: const ['email', 'profile'],
          );

  final GoogleSignIn _googleSignIn;

  /// Prompts native Google Account selector and returns the RS256-signed ID Token.
  /// Returns `null` if the user cancels account selection.
  Future<String?> getIdToken() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled account selection
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      return idToken;
    } catch (e) {
      // Re-throw genuine sign-in errors to caller
      rethrow;
    }
  }

  /// Signs out from Google Play Services on device.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}

/// Global provider for [GoogleSignInService].
final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});
