import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  bool _googleSignInReady = false;

  Future<void> _ensureGoogleSignInReady() async {
    if (_googleSignInReady) return;
    String? serverClientId;
    try {
      if (dotenv.isInitialized) {
        serverClientId = dotenv.maybeGet('GOOGLE_SERVER_CLIENT_ID');
      }
    } catch (_) {
      serverClientId = null;
    }
    await _googleSignIn.initialize(
      serverClientId: (serverClientId != null && serverClientId.isNotEmpty)
          ? serverClientId
          : null,
    );
    _googleSignInReady = true;
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw FirebaseAuthException(
        code: 'user-record-missing',
        message: 'No profile found for this account.',
      );
    }

    return (doc.data()?['role'] as String?) ?? 'customer';
  }

  Future<void> registerCustomer({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String address,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;

    await _firestore.collection('users').doc(uid).set({
      'name': fullName,
      'email': email.trim(),
      'phone': phone,
      'address': address,
      'role': 'customer',
      'email_verified': false,
      'created_at': FieldValue.serverTimestamp(),
    });

    await _sendVerificationEmailSafely(credential.user!);
  }

  Future<void> registerFarmer({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String businessName,
    required String marketLocation,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;

    await _firestore.collection('users').doc(uid).set({
      'name': fullName,
      'email': email.trim(),
      'phone': phone,
      'role': 'farmer',
      'email_verified': false,
      'created_at': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('farmers').doc(uid).set({
      'user_id': uid,
      'business_name': businessName,
      'market_location': marketLocation,
      'description': '',
      'rating': 0.0,
    });

    await _sendVerificationEmailSafely(credential.user!);
  }

  Future<String> signInWithGoogle() async {
    await _ensureGoogleSignInReady();

    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign-in was cancelled.',
        );
      }
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: e.description ?? 'Google sign-in failed. Please try again.',
      );
    }

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-no-token',
        message: 'Google sign-in did not return a token. Check that '
            'GOOGLE_SERVER_CLIENT_ID is set in your .env.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);

    final userCredential = await _auth.signInWithCredential(credential);
    final uid = userCredential.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();

    if (doc.exists) {
      return (doc.data()?['role'] as String?) ?? 'customer';
    }

    await _firestore.collection('users').doc(uid).set({
      'name': userCredential.user!.displayName ?? '',
      'email': userCredential.user!.email ?? '',
      'role': 'customer',
      'email_verified': userCredential.user!.emailVerified,
      'created_at': FieldValue.serverTimestamp(),
    });
    return 'customer';
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Please sign in again to resend the verification email.',
      );
    }
    if (user.emailVerified) return;
    await _sendVerificationEmailSafely(user);
  }

  Future<void> _sendVerificationEmailSafely(User user) async {
    try {
      await user.sendEmailVerification();
    } catch (e) {
      debugPrint('Could not send verification email: $e');
    }
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = _auth.currentUser;
    final verified = refreshed?.emailVerified ?? false;

    if (verified && refreshed != null) {
      await _firestore
          .collection('users')
          .doc(refreshed.uid)
          .update({'email_verified': true}).catchError((_) {});
    }
    return verified;
  }

  Future<void> signOut() async {
    try {
      await _ensureGoogleSignInReady();
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google sign-out skipped: $e');
    }
    await _auth.signOut();
  }

  String messageForError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'weak-password':
          return 'Choose a stronger password (at least 8 characters).';
        case 'network-request-failed':
          return 'No internet connection — please try again.';
        case 'too-many-requests':
          return 'Too many attempts — please wait a moment and try again.';
        case 'user-record-missing':
          return error.message ?? 'No profile found for this account.';
        case 'no-current-user':
          return error.message ?? 'Please sign in again.';
        case 'google-sign-in-cancelled':
          return 'Google sign-in was cancelled.';
        case 'google-sign-in-failed':
          return error.message ?? 'Google sign-in failed. Please try again.';
        case 'google-sign-in-no-token':
          return error.message ?? 'Google sign-in could not be completed.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  String messageForResetError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'user-not-found':
          return 'No account found for that email address.';
        case 'network-request-failed':
          return 'No internet connection — please try again.';
        case 'too-many-requests':
          return 'Too many attempts — please wait a moment and try again.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
