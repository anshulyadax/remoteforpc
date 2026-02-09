import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:remote_protocol/remote_protocol.dart';

/// Authentication state management
class AppAuthState extends ChangeNotifier {
  final SupabaseAuthService _authService;
  User? _currentUser;
  Session? _currentSession;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _requiresEmailConfirmation = false;

  AppAuthState() : _authService = SupabaseAuthService(Supabase.instance.client) {
    _currentUser = _authService.currentUser;
    _currentSession = _authService.currentSession;
    _listenToAuthChanges();
    if (_currentUser != null) {
      _loadUserProfile();
    }
  }

  /// Current user
  User? get currentUser => _currentUser;

  /// Current session
  Session? get currentSession => _currentSession;

  /// User profile
  UserProfile? get userProfile => _userProfile;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentSession != null;

  /// Whether email confirmation is required after sign up
  bool get requiresEmailConfirmation => _requiresEmailConfirmation;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Error message
  String? get errorMessage => _errorMessage;

  /// Auth service getter
  SupabaseAuthService get authService => _authService;

  /// Listen to auth state changes
  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((authChange) {
      _currentSession = authChange.session;
      _currentUser = _currentSession?.user;
      _requiresEmailConfirmation = false;
      if (_currentUser != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }
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
    _requiresEmailConfirmation = false;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      _currentSession = response.session;
      _currentUser = response.session?.user;
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
    _requiresEmailConfirmation = false;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
      );

      _currentSession = response.session;
      _currentUser = response.session?.user;
      if (response.session == null) {
        // Common when email confirmation is required
        _requiresEmailConfirmation = true;
      }
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
    _requiresEmailConfirmation = false;
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
    _requiresEmailConfirmation = false;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signInAnonymously();
      _currentSession = response.session;
      _currentUser = response.session?.user;
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
      _currentSession = null;
      _requiresEmailConfirmation = false;
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

  Future<bool> updateEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(email: email.trim()),
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
      _errorMessage = 'Failed to update email';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
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
      _errorMessage = 'Failed to update password';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Load user profile from metadata
  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;

    try {
      final metadata = _currentUser!.userMetadata;
      _userProfile = UserProfile(
        id: _currentUser!.id,
        email: _currentUser!.email,
        displayName: metadata?['display_name'] as String?,
        avatarUrl: metadata?['avatar_url'] as String?,
        phoneNumber: metadata?['phone_number'] as String?,
        createdAt: DateTime.tryParse(_currentUser!.createdAt),
        metadata: metadata,
      );
      notifyListeners();
    } catch (e) {
      print('Failed to load user profile: $e');
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final metadata = <String, dynamic>{
        ..._currentUser?.userMetadata ?? {},
      };

      if (displayName != null) metadata['display_name'] = displayName;
      if (avatarUrl != null) metadata['avatar_url'] = avatarUrl;
      if (phoneNumber != null) metadata['phone_number'] = phoneNumber;

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: metadata),
      );

      await _loadUserProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update profile';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
