import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:remote_protocol/remote_protocol.dart';

/// Authentication state management
class AuthState extends ChangeNotifier {
  final SupabaseAuthService _authService;
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthState() : _authService = SupabaseAuthService(Supabase.instance.client) {
    _currentUser = _authService.currentUser;
    _listenToAuthChanges();
  }

  /// Current user
  User? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Error message
  String? get errorMessage => _errorMessage;

  /// Auth service getter
  SupabaseAuthService get authService => _authService;

  /// Listen to auth state changes
  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((AuthState authState) {
      _currentUser = authState.session?.user;
      notifyListeners();
    });
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      _currentUser = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
      );

      _currentUser = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.redirectUrl,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to sign in with Google';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in anonymously (for LAN-only mode)
  Future<bool> signInAnonymously() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signInAnonymously();
      _currentUser = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to continue anonymously';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = 'Failed to sign out';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send reset email';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
