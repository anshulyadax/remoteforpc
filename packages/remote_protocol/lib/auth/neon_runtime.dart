import 'package:supabase_flutter/supabase_flutter.dart' as sb;

typedef NeonClient = sb.SupabaseClient;
typedef NeonUser = sb.User;
typedef NeonSession = sb.Session;
typedef NeonAuthException = sb.AuthException;
typedef NeonOAuthProvider = sb.OAuthProvider;
typedef NeonUserAttributes = sb.UserAttributes;
typedef NeonAuthState = sb.AuthState;
typedef NeonRealtimeChannel = sb.RealtimeChannel;
typedef NeonRealtimeSubscribeStatus = sb.RealtimeSubscribeStatus;

class NeonRuntime {
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) {
    return sb.Supabase.initialize(url: url, anonKey: anonKey);
  }

  static NeonClient get client => sb.Supabase.instance.client;

  static Future<bool> signInWithOAuth({
    required NeonOAuthProvider provider,
    String? redirectTo,
  }) {
    return client.auth.signInWithOAuth(provider, redirectTo: redirectTo);
  }
}
