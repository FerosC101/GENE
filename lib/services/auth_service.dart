// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pulse/data/models/user_model.dart';
import 'package:pulse/data/models/user_type.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        final userData = await getUserData(result.user!.uid);
        return userData;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Login error: ${e.code}');
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserType userType,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        final userData = {
          'email': email,
          'fullName': fullName,
          'userType': userType.name, // CRITICAL: Save as string
          'phoneNumber': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          ...?additionalData,
        };

        await _firestore.collection('users').doc(result.user!.uid).set(userData);

        await result.user!.updateDisplayName(fullName);

        // Verify data was saved
        final savedUser = await getUserData(result.user!.uid);
        return savedUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Registration error: ${e.code}');
      throw _handleAuthException(e);
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final userModel = UserModel.fromFirestore(doc);
        return userModel;
      } else {
        debugPrint('❌ User document does not exist');
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching user data: $e');
      throw Exception('Failed to get user data: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      case 'invalid-credential':
        return 'Invalid credentials provided.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}