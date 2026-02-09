import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase authentication service
class SupabaseAuthService {
  final SupabaseClient _client;
  
  SupabaseAuthService(this._client);

  /// Get the Supabase client
  SupabaseClient get client => _client;

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Auth state change stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'remoteforpc://login-callback',
      );
      return true;
    } catch (e) {
      print('Error signing in with Google: $e');
      return false;
    }
  }

  /// Sign in with GitHub
  Future<bool> signInWithGitHub() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: 'remoteforpc://login-callback',
      );
      return true;
    } catch (e) {
      print('Error signing in with GitHub: $e');
      return false;
    }
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'remoteforpc://login-callback',
      );
      return true;
    } catch (e) {
      print('Error signing in with Apple: $e');
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      print('Error signing in with email: $e');
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail(String email, String password) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      print('Error signing up: $e');
      return false;
    }
  }

  /// Sign in anonymously (device-only pairing mode)
  Future<bool> signInAnonymously() async {
    try {
      await _client.auth.signInAnonymously();
      return true;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Get access token for API calls
  String? get accessToken => currentSession?.accessToken;

  /// Get user ID
  String? get userId => currentUser?.id;
}
