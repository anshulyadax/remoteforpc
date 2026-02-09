import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:remote_protocol/remote_protocol.dart';

/// Authentication state manager
class AuthState extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileService _profileService = ProfileService();
  
  User? _user;
  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  AuthState() {
    _init();
  }

  // Getters
  User? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> _init() async {
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _loadProfile();
      } else {
        _profile = null;
      }
      notifyListeners();
    });

    // Check current session
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _user = session.user;
      await _loadProfile();
    }
  }

  /// Load user profile from database
  Future<void> _loadProfile() async {
    if (_user == null) return;

    try {
      _profile = await _profileService.getProfile(_user!.id);
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
      final response = await _supabase.auth.signInWithPassword(
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
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        
        // Create profile
        await _profileService.createProfile(
          userId: _user!.id,
          username: username,
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
      await _supabase.auth.signOut();
      _user = null;
      _profile = null;
      _error = null;
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? username,
    String? fullName,
    String? avatarUrl,
  }) async {
    if (_user == null || _profile == null) return false;

    _setLoading(true);
    _error = null;

    try {
      await _profileService.updateProfile(
        userId: _user!.id,
        username: username,
        fullName: fullName,
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
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
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
      await _supabase.auth.resetPasswordForEmail(email);
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
    if (error is AuthException) {
      return error.message;
    }
    return error.toString();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
