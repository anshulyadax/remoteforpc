# Profile and Account Settings - Feature Documentation

## Overview
Enhanced authentication system with complete user profile management and account settings capabilities.

## ✅ Completed Features

### 1. User Profile Model
- **Location**: `packages/remote_protocol/lib/models/user_profile.dart`
- **Fields**:
  - `id` - Unique user identifier
  - `email` - User email address
  - `displayName` - User's display name (customizable)
  - `avatarUrl` - Profile picture URL
  - `phoneNumber` - Contact phone number
  - `createdAt` - Account creation timestamp
  - `updatedAt` - Last profile update timestamp
  - `metadata` - Additional custom data

### 2. Profile Management State
- **Location**: `apps/client_mobile/lib/state/auth_state.dart`
- **New Methods**:
  - `updateProfile()` - Update user profile information
  - `_loadUserProfile()` - Load profile from Supabase metadata
  - Automatic profile loading on authentication

### 3. Profile Edit Screen
- **Location**: `apps/client_mobile/lib/screens/profile_edit_screen.dart`
- **Features**:
  - Avatar display and placeholder for photo upload
  - Edit display name, phone number, and avatar URL
  - Read-only email display
  - Account information display (User ID, creation date)
  - Real-time error handling
  - Loading states for async operations

### 4. Enhanced Account Settings
- **Location**: `apps/client_mobile/lib/screens/account_settings_screen.dart`
- **Features**:
  - Profile card with avatar, display name, and phone
  - Quick access to profile editing
  - Email management (change email with confirmation)
  - Password management (change password, reset via email)
  - Account information display
  - Sign out functionality

### 5. Supabase Configuration
- **Location**: `packages/remote_protocol/lib/config/supabase_config.dart`
- **Features**:
  - Environment toggle (`useLocalSupabase`)
  - Local development configuration (http://127.0.0.1:54321)
  - Production configuration (hosted Supabase)
  - Easy switching between environments

### 6. Database Schema
- **Location**: `supabase/migrations/20260209000001_create_profiles_table.sql`
- **Features**:
  - `profiles` table with user data
  - Row Level Security (RLS) policies
  - Automatic profile creation on user signup
  - Automatic timestamp updates
  - Performance indexes

## 🚀 Usage Instructions

### For Users (Mobile App)

1. **Sign In/Sign Up**
   - Open the app and sign in or create an account
   - Email/password or Google authentication supported

2. **View Account Settings**
   - Tap the account/profile icon in the app header
   - Select "Account settings" from the menu

3. **Edit Profile**
   - From account settings, tap the edit icon on the profile card
   - Update your display name, phone number, or avatar URL
   - Tap "Save Changes" to persist updates

4. **Change Email**
   - From account settings, tap the edit icon next to Email
   - Enter your new email address
   - Check your inbox for a confirmation email

5. **Change Password**
   - From account settings, tap the edit icon next to Password
   - Enter and confirm your new password
   - Tap "Save" to update

### For Developers

#### Local Development Setup

1. **Start Supabase Locally**
   ```bash
   # Ensure Docker is running
   open -a Docker
   
   # Start Supabase services
   supabase start
   ```

2. **Switch to Local Supabase**
   ```dart
   // In packages/remote_protocol/lib/config/supabase_config.dart
   static const bool useLocalSupabase = true;
   ```

3. **Access Local Services**
   - Studio: http://127.0.0.1:54323
   - API: http://127.0.0.1:54321
   - Database: postgresql://postgres:postgres@127.0.0.1:54322/postgres

4. **Apply Migrations**
   ```bash
   # Reset database and apply all migrations
   supabase db reset
   
   # Or apply new migrations only
   supabase db push
   ```

#### Production Deployment

1. **Switch to Production**
   ```dart
   // In packages/remote_protocol/lib/config/supabase_config.dart
   static const bool useLocalSupabase = false;
   ```

2. **Push Migrations to Production**
   ```bash
   # Link to your production project
   supabase link --project-ref YOUR_PROJECT_REF
   
   # Push migrations
   supabase db push
   ```

## 🔧 Extending the Features

### Adding Custom Profile Fields

1. **Update the Model**
   ```dart
   // In user_profile.dart
   class UserProfile {
     final String? bio;  // Add new field
     // ...
   }
   ```

2. **Update the Database**
   ```sql
   -- Create new migration
   ALTER TABLE public.profiles ADD COLUMN bio TEXT;
   ```

3. **Update the UI**
   ```dart
   // In profile_edit_screen.dart
   TextFormField(
     controller: _bioController,
     decoration: const InputDecoration(labelText: 'Bio'),
   )
   ```

### Adding Profile Photo Upload

1. **Install Image Picker**
   ```bash
   cd apps/client_mobile
   flutter pub add image_picker
   ```

2. **Implement Upload Logic**
   ```dart
   Future<String?> _uploadAvatar(File image) async {
     final bytes = await image.readAsBytes();
     final fileExt = image.path.split('.').last;
     final fileName = '${UUID.v4()}.$fileExt';
     final filePath = 'avatars/$fileName';
     
     await Supabase.instance.client.storage
       .from('avatars')
       .uploadBinary(filePath, bytes);
     
     return Supabase.instance.client.storage
       .from('avatars')
       .getPublicUrl(filePath);
   }
   ```

## 🐛 Fixed Issues

### Login Issues Resolved
1. ✅ Proper error handling for authentication failures
2. ✅ Email confirmation flow for new signups
3. ✅ Password reset via email
4. ✅ Anonymous authentication for LAN-only mode
5. ✅ Google OAuth integration
6. ✅ Session persistence and auto-login

### Account Management Issues Resolved
1. ✅ Profile data persistence across app restarts
2. ✅ Real-time profile updates
3. ✅ Email change with confirmation
4. ✅ Password strength validation
5. ✅ Secure sign-out functionality

## 📱 UI/UX Improvements

1. **Profile Avatar** - Visual user identification with image support
2. **Form Validation** - Real-time input validation with helpful error messages
3. **Loading States** - Clear feedback during async operations
4. **Error Handling** - User-friendly error messages with dismissible alerts
5. **Navigation** - Intuitive flow between screens
6. **Accessibility** - Proper labels and semantic elements

## 🔐 Security Features

1. **Row Level Security** - Database-level access control
2. **Password Requirements** - Minimum 6 characters enforced
3. **Email Verification** - Confirm new email addresses
4. **Secure Password Reset** - Email-based password recovery
5. **Session Management** - Automatic token refresh and expiration

## 📊 Database Schema

```sql
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  email TEXT,
  display_name TEXT,
  avatar_url TEXT,
  phone_number TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

## 🔗 Integration Points

- **Connection Screen** - Profile menu in app bar
- **Touchpad Screen** - Settings button (TODO: add profile access)
- **Auth State** - Centralized authentication and profile management
- **Supabase** - Real-time data sync and authentication

## 🚧 Future Enhancements

- [ ] Photo upload from device camera/gallery
- [ ] Profile picture cropping and editing
- [ ] Email preferences and notifications
- [ ] Two-factor authentication (2FA)
- [ ] Social profile connections
- [ ] Privacy settings
- [ ] Account deletion
- [ ] Activity log and login history

## 📝 Testing Checklist

- [ ] Sign up with email/password
- [ ] Sign in with existing account
- [ ] Sign in with Google OAuth
- [ ] Anonymous sign in
- [ ] Edit profile information
- [ ] Change email address
- [ ] Change password
- [ ] Reset password via email
- [ ] View account information
- [ ] Sign out
- [ ] Profile persistence after app restart
- [ ] Error handling for network issues
- [ ] Local Supabase connection
- [ ] Production Supabase connection

## 📚 Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Material Design 3](https://m3.material.io/)
