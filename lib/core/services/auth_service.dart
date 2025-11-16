import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

// Auth result class
class AuthResult {
  final bool success;
  final User? user;
  final String? errorMessage;
  final String? successMessage;

  AuthResult({
    required this.success,
    this.user,
    this.errorMessage,
    this.successMessage,
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Auth change user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (result.user != null) {
        return AuthResult(success: true, user: result.user);
      } else {
        return AuthResult(success: false, errorMessage: 'Sign in failed');
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, errorMessage: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'An unexpected error occurred');
    }
  }

  // Register with email and password
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null) {
        // Update display name
        await result.user!.updateDisplayName(fullName);
        
        // Create user document in Firestore
        try {
          await FirestoreService.createUserDocument(result.user!, fullName);
        } catch (e) {
          debugPrint('Warning: Could not create user document in Firestore: $e');
          // Continue with success even if Firestore fails (in case API not enabled yet)
        }
        
        return AuthResult(success: true, user: result.user, successMessage: 'Account created successfully!');
      } else {
        return AuthResult(success: false, errorMessage: 'Registration failed');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getErrorMessage(e.code);
      print('FirebaseAuthException during registration: ${e.code} - ${e.message}');
      return AuthResult(success: false, errorMessage: errorMessage);
    } catch (e) {
      print('Unexpected error during registration: $e');
      return AuthResult(success: false, errorMessage: 'An unexpected error occurred: ${e.toString()}');
    }
  }

  // Firestore methods temporarily disabled until Firestore API is enabled

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  // Reset password
  Future<AuthResult> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult(
        success: true, 
        successMessage: 'Password reset email sent successfully'
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, errorMessage: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'An unexpected error occurred');
    }
  }

  // User data methods using Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      return await FirestoreService.getUserData();
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      await FirestoreService.updateUserSettings(settings);
    } catch (e) {
      debugPrint('Error updating user settings: $e');
    }
  }

  // Get user settings from Firestore
  Future<Map<String, dynamic>?> getUserSettings() async {
    try {
      return await FirestoreService.getUserSettings();
    } catch (e) {
      debugPrint('Error getting user settings: $e');
      return null;
    }
  }

  // Get Firebase error messages
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'configuration-not-found':
        return 'Firebase Authentication is not enabled. Please enable it in Firebase Console.';
      case 'app-not-authorized':
        return 'App not authorized for Firebase Authentication.';
      case 'internal-error':
        return 'Internal error. Please check Firebase configuration.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}