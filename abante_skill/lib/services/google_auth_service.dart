import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thrown when someone signs in with Google but their email already belongs
/// to an account that uses a different sign-in method (e.g. email+password)
/// and Firebase won't merge them automatically. Sign in to that account,
/// then call [GoogleAuthService.linkPending] to attach Google to it — so
/// both methods open the same account and the same progress.
class GoogleAccountLinkRequired implements Exception {
  const GoogleAccountLinkRequired({required this.email, required this.credential});

  final String email;
  final AuthCredential credential;
}

/// Wraps Google Sign-In + Firebase credential exchange.
///
/// Account merging: Firebase is set to "one account per email", so a Google
/// sign-in for an email that already has an account lands on that same
/// account (same uid), and all Firestore progress keyed by uid carries over.
/// The rare case Firebase can't resolve on its own surfaces as
/// [GoogleAccountLinkRequired].
class GoogleAuthService {
  GoogleAuthService._();

  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }

  static Future<AuthCredential> _googleCredential() async {
    await _ensureInitialized();
    final googleUser = await GoogleSignIn.instance.authenticate();
    return GoogleAuthProvider.credential(idToken: googleUser.authentication.idToken);
  }

  /// Runs the Google sign-in flow and exchanges the result for a Firebase
  /// user. Throws if the user cancels or the exchange fails.
  static Future<UserCredential> signIn() async {
    final credential = await _googleCredential();
    try {
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential' && e.email != null) {
        throw GoogleAccountLinkRequired(email: e.email!, credential: e.credential ?? credential);
      }
      rethrow;
    }
  }

  /// Signs in to the existing email+password account for [pending] and
  /// links Google to it.
  static Future<void> linkPending(GoogleAccountLinkRequired pending, String password) async {
    final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: pending.email,
      password: password,
    );
    await result.user!.linkWithCredential(pending.credential);
  }

  /// Re-confirms a Google user's identity, needed before sensitive actions
  /// like deleting the account.
  static Future<void> reauthenticate(User user) async {
    final credential = await _googleCredential();
    await user.reauthenticateWithCredential(credential);
  }

  /// Signs out of Google too, so the next "Continue with Google" lets the
  /// person pick an account instead of silently reusing the last one.
  static Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Not signed in with Google; nothing to do.
    }
  }

  static bool isGoogleUser(User user) => user.providerData.any((p) => p.providerId == 'google.com');

  static bool hasPassword(User user) => user.providerData.any((p) => p.providerId == 'password');
}
