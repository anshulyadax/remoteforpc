import 'package:flutter/foundation.dart';

/// Neon Auth configuration constants
/// 
/// Neon Auth is a managed REST API service built on Better Auth that connects
/// directly to your Neon database. All authentication data lives in the
/// neon_auth schema in your database.
/// 
/// Architecture:
/// Your App (SDK) -> Neon Auth Service (REST API) -> Your Neon Database (neon_auth schema)
/// 
/// NOTE: Supabase has been removed from this project. This configuration is kept
/// for reference but may need updates for direct Neon Auth implementation.
class NeonAuthConfig {
  // Environment flag - set to true for local development
  static const bool useLocalNeon = false;
  
  // Neon cloud configuration. Keep credentials outside source control.
  // Base URL for authentication (Neon Auth REST API)
  static const String _productionUrl = String.fromEnvironment(
    'NEON_URL',
    defaultValue: 'https://ep-dawn-snow-aichjaw3.neonauth.c-4.us-east-1.aws.neon.tech/neondb',
  );
  // API key for authentication (obtained from Neon Console)
  static const String _productionAnonKey = String.fromEnvironment(
    'NEON_ANON_KEY',
    defaultValue: 'napi_kwff6ecwz6a7bvxw0cw93ulgeozk04jhdw09h2sx8wspt877yxuul594ncuq8bd3',
  );
  
  // Local auth project configuration (development only)
  static const String _localUrl = 'http://127.0.0.1:54321';
  static const String _localAnonKey = 'local-dev-key';
  
  // Neon Auth endpoints
  // REST API endpoint for authentication operations (sign-in, sign-up, OAuth)
  static const String authEndpoint = String.fromEnvironment(
    'NEON_AUTH_URL',
    defaultValue: 'https://ep-dawn-snow-aichjaw3.neonauth.c-4.us-east-1.aws.neon.tech/neondb/auth',
  );
  // JWKS endpoint for JWT token validation (used by Data API for RLS)
  static const String jwksEndpoint = String.fromEnvironment(
    'NEON_JWKS_URL',
    defaultValue: 'https://ep-dawn-snow-aichjaw3.neonauth.c-4.us-east-1.aws.neon.tech/neondb/auth/.well-known/jwks.json',
  );
  // PostgreSQL connection string for direct database access
  static const String databaseUrl = String.fromEnvironment(
    'NEON_DATABASE_URL',
    defaultValue: 'postgresql://neondb_owner:npg_Lh6orRMngZO9@ep-dawn-snow-aichjaw3-pooler.c-4.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require',
  );
  
  // Project information
  static const String neonOrg = 'org-mute-silence-09730628';
  static const String neonProject = 'damp-unit-14958113';
  
  // Database schema where auth data is stored
  // All authentication data (users, sessions, OAuth configs) lives here
  // You can query these tables directly with SQL:
  // - neon_auth.user
  // - neon_auth.session
  // - neon_auth.account
  // - neon_auth.verification
  static const String authSchema = 'neon_auth';
  
  // Active configuration based on environment
  static String get authUrl => useLocalNeon ? _localUrl : _productionUrl;
  static String get anonKey {
    if (useLocalNeon) {
      return _localAnonKey;
    }
    if (_productionAnonKey.isEmpty) {
      throw StateError(
        'Missing NEON_ANON_KEY. Pass it via --dart-define=NEON_ANON_KEY=...',
      );
    }
    return _productionAnonKey;
  }
  
  // Deep link scheme for OAuth callbacks
  static const String redirectScheme = 'remoteforpc';
  static String get redirectUrl {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return '$redirectScheme://login-callback';
  }
  
  // Realtime channel prefix for remote control
  static const String channelPrefix = 'remote:';
}
