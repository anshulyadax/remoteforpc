import 'package:flutter/foundation.dart';
import 'package:remote_protocol/remote_protocol.dart';

/// Authentication state manager
class AuthState extends ChangeNotifier {
  final NeonClient _authClient = NeonRuntime.client;
  late final ProfileService _profileService = ProfileService(_authClient);
  
  NeonUser? _user;
  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  AuthState() {
    _init();
  }

  // Getters
  NeonUser? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> _init() async {
    // Listen to auth state changes
    _authClient.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _loadProfile();
      } else {
        _profile = null;
      }
      notifyListeners();
    });

    // Check current session
    final session = _authClient.auth.currentSession;
    if (session != null) {
      _user = session.user;
      await _loadProfile();
    }
  }

  /// Load user profile from database
  Future<void> _loadProfile() async {
    if (_user == null) return;

    try {
      _profile = await _profileService.fetchProfile(_user!.id);
      notifyListeners();
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _authClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        await _loadProfile();
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } catch (e) {
      _error = _formatError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Sign up with email, password, and username
  Future<bool> signUp(String email, String password, String username) async {
    _setLoading(true);
    _error = null;

    try {
      // Sign up user
      final response = await _authClient.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        
        // Create profile
        await _profileService.createProfile(
          userId: _user!.id,
          displayName: email.split('@')[0], // Use email prefix as initial display name
          email: email,
        );
        
        await _loadProfile();
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } catch (e) {
      _error = _formatError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await _authClient.auth.signOut();
      _user = null;
      _profile = null;
      _error = null;
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in / sign up with GitHub OAuth
  Future<bool> signInWithGitHub() async {
    _setLoading(true);
    _error = null;

    try {
      await NeonRuntime.signInWithOAuth(
        provider: NeonOAuthProvider.github,
        redirectTo: NeonAuthConfig.redirectUrl,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _formatError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    if (_user == null || _profile == null) return false;

    _setLoading(true);
    _error = null;

    try {
      await _profileService.updateProfile(
        userId: _user!.id,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      await _loadProfile();
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _formatError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword(String newPassword) async {
    _setLoading(true);
    _error = null;

    try {
      await _authClient.auth.updateUser(
        NeonUserAttributes(password: newPassword),
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _formatError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Reset password via email
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _error = null;

    try {
      await _authClient.auth.resetPasswordForEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _formatError(e);
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _formatError(dynamic error) {
    if (error is NeonAuthException) {
      return error.message;
    }
    return error.toString();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
