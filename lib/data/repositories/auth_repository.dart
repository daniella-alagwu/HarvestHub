import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    await _googleSignIn.initialize();
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
      'created_at': FieldValue.serverTimestamp(),
    });
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
      'created_at': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('farmers').doc(uid).set({
      'user_id': uid,
      'business_name': businessName,
      'market_location': marketLocation,
      'description': '',
      'rating': 0.0,
    });
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
      rethrow;
    }

    final googleAuth = googleUser.authentication;
    final credential =
        GoogleAuthProvider.credential(idToken: googleAuth.idToken);

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
      'created_at': FieldValue.serverTimestamp(),
    });
    return 'customer';
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
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
        case 'google-sign-in-cancelled':
          return 'Google sign-in was cancelled.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
