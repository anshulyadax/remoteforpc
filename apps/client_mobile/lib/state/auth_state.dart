import 'package:flutter/foundation.dart';

import 'package:remote_protocol/remote_protocol.dart';

/// Authentication state management
/// 
/// This class manages user authentication and profile data using Neon auth.
/// It handles:
/// - Email/password authentication
/// - OAuth (Google, etc.)
/// - Anonymous authentication (for LAN-only mode)
/// - Profile management (stored in profiles table)
/// - Session management
/// 
/// Profile data is stored in the 'profiles' table and synced with
/// user metadata for consistency. The ProfileService handles all database
/// operations for profiles.
class AppAuthState extends ChangeNotifier {
  final NeonAuthService _authService;
  final ProfileService _profileService;
  NeonUser? _currentUser;
  NeonSession? _currentSession;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _requiresEmailConfirmation = false;

  AppAuthState() 
      : _authService = NeonAuthService(NeonRuntime.client),
        _profileService = ProfileService(NeonRuntime.client) {
    _currentUser = _authService.currentUser;
    _currentSession = _authService.currentSession;
    _listenToAuthChanges();
    if (_currentUser != null) {
      _loadUserProfile();
    }
  }

  /// Current user
  NeonUser? get currentUser => _currentUser;

  /// Current session
  NeonSession? get currentSession => _currentSession;

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
  NeonAuthService get authService => _authService;

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
      final response = await NeonRuntime.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      _currentSession = response.session;
      _currentUser = response.session?.user;
      
      if (_currentUser != null) {
        await _loadUserProfile();
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on NeonAuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid') || 
          e.message.toLowerCase().contains('credentials')) {
        _errorMessage = 'Invalid email or password. Please try again.';
      } else if (e.message.toLowerCase().contains('email not confirmed')) {
        _errorMessage = 'Please confirm your email before signing in.';
      } else {
        _errorMessage = e.message;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during sign in';
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
      final response = await NeonRuntime.client.auth.signUp(
        email: email.trim(),
        password: password,
      );

      _currentSession = response.session;
      _currentUser = response.session?.user;
      
      if (response.session == null) {
        // Common when email confirmation is required
        _requiresEmailConfirmation = true;
      } else if (_currentUser != null) {
        // User signed up and got a session, ensure profile exists
        await _loadUserProfile();
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on NeonAuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered')) {
        _errorMessage = 'This email is already registered. Please sign in instead.';
      } else {
        _errorMessage = e.message;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during signup';
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
      await NeonRuntime.signInWithOAuth(
        provider: NeonOAuthProvider.google,
        redirectTo: NeonAuthConfig.redirectUrl,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on NeonAuthException catch (e) {
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

  /// Sign in with GitHub
  Future<bool> signInWithGitHub() async {
    _isLoading = true;
    _errorMessage = null;
    _requiresEmailConfirmation = false;
    notifyListeners();

    try {
      await NeonRuntime.signInWithOAuth(
        provider: NeonOAuthProvider.github,
        redirectTo: NeonAuthConfig.redirectUrl,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on NeonAuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to sign in with GitHub';
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
      final response = await NeonRuntime.client.auth.signInAnonymously();
      _currentSession = response.session;
      _currentUser = response.session?.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on NeonAuthException catch (e) {
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
      await NeonRuntime.client.auth.resetPasswordForEmail(email.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } on NeonAuthException catch (e) {
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
      await NeonRuntime.client.auth.updateUser(
        NeonUserAttributes(email: email.trim()),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on NeonAuthException catch (e) {
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
      await NeonRuntime.client.auth.updateUser(
        NeonUserAttributes(password: password),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on NeonAuthException catch (e) {
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
      // Fetch profile from database
      _userProfile = await _profileService.ensureProfile(
        userId: _currentUser!.id,
        email: _currentUser!.email,
      );
      notifyListeners();
    } catch (e) {
      print('Failed to load user profile: $e');
      // Fallback to metadata if database fetch fails
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
        print('Failed to load profile from metadata: $e');
      }
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
      if (_currentUser == null) {
        _errorMessage = 'No user logged in';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update profile in database
      final updatedProfile = await _profileService.updateProfile(
        userId: _currentUser!.id,
        displayName: displayName,
        avatarUrl: avatarUrl,
        phoneNumber: phoneNumber,
      );

      if (updatedProfile != null) {
        _userProfile = updatedProfile;
        
        // Also update user metadata for consistency
        final metadata = <String, dynamic>{
          ..._currentUser?.userMetadata ?? {},
        };

        if (displayName != null) metadata['display_name'] = displayName;
        if (avatarUrl != null) metadata['avatar_url'] = avatarUrl;
        if (phoneNumber != null) metadata['phone_number'] = phoneNumber;

        try {
          await NeonRuntime.client.auth.updateUser(
            NeonUserAttributes(data: metadata),
          );
        } catch (e) {
          print('Warning: Failed to update user metadata: $e');
          // Continue anyway since database was updated
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on NeonAuthException catch (e) {
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
