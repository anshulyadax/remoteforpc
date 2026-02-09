import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

/// Service for managing user profiles in Supabase database
/// 
/// This service handles all CRUD operations for user profiles stored in the
/// Supabase 'profiles' table. Profiles are automatically created via a database
/// trigger when a user signs up (see migration 20260209000001_create_profiles_table.sql).
/// 
/// The profiles table structure:
/// - id: UUID (references auth.users, primary key)
/// - email: TEXT
/// - display_name: TEXT
/// - avatar_url: TEXT
/// - phone_number: TEXT  
/// - created_at: TIMESTAMP
/// - updated_at: TIMESTAMP
class ProfileService {
  final SupabaseClient _client;

  ProfileService(this._client);

  /// Fetch user profile from database
  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  /// Create a new user profile
  Future<UserProfile?> createProfile({
    required String userId,
    required String email,
    String? displayName,
    String? avatarUrl,
    String? phoneNumber,
  }) async {
    try {
      final data = {
        'id': userId,
        'email': email,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'phone_number': phoneNumber,
      };

      final response = await _client
          .from('profiles')
          .insert(data)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error creating profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<UserProfile?> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
    String? phoneNumber,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;

      if (updates.isEmpty) {
        // No updates to make
        return await fetchProfile(userId);
      }

      final response = await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error updating profile: $e');
      return null;
    }
  }

  /// Delete user profile
  Future<bool> deleteProfile(String userId) async {
    try {
      await _client
          .from('profiles')
          .delete()
          .eq('id', userId);
      return true;
    } catch (e) {
      print('Error deleting profile: $e');
      return false;
    }
  }

  /// Ensure profile exists, create if not
  Future<UserProfile?> ensureProfile({
    required String userId,
    required String? email,
  }) async {
    // Try to fetch existing profile
    var profile = await fetchProfile(userId);
    
    if (profile != null) {
      return profile;
    }

    // Profile doesn't exist, create it
    if (email != null) {
      profile = await createProfile(
        userId: userId,
        email: email,
      );
    }

    return profile;
  }
}
