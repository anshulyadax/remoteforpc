/// Supabase configuration constants
class SupabaseConfig {
  // Environment flag - set to true for local development
  static const bool useLocalSupabase = false;
  
  // Production Supabase project configuration
  static const String _productionUrl = 'https://hebcaaswkwvmpnhjakxe.supabase.co';
  static const String _productionAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhlYmNhYXN3a3d2bXBuaGpha3hlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2NDI2NjYsImV4cCI6MjA4NjIxODY2Nn0.7zUk135epBNrEuWrz-KgHpp7lyIlLMc67TLgT6GAkxk';
  
  // Local Supabase project configuration (from supabase start)
  static const String _localUrl = 'http://127.0.0.1:54321';
  static const String _localAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
  
  // Active configuration based on environment
  static String get supabaseUrl => useLocalSupabase ? _localUrl : _productionUrl;
  static String get supabaseAnonKey => useLocalSupabase ? _localAnonKey : _productionAnonKey;
  
  // Deep link scheme for OAuth callbacks
  static const String redirectScheme = 'remoteforpc';
  static const String redirectUrl = '$redirectScheme://login-callback';
  
  // Realtime channel prefix for remote control
  static const String channelPrefix = 'remote:';
}
