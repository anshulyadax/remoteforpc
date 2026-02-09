/// Supabase configuration constants
class SupabaseConfig {
  // Supabase project configuration
  static const String supabaseUrl = 'https://hebcaaswkwvmpnhjakxe.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhlYmNhYXN3a3d2bXBuaGpha3hlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2NDI2NjYsImV4cCI6MjA4NjIxODY2Nn0.7zUk135epBNrEuWrz-KgHpp7lyIlLMc67TLgT6GAkxk';
  
  // Deep link scheme for OAuth callbacks
  static const String redirectScheme = 'remoteforpc';
  static const String redirectUrl = '$redirectScheme://login-callback';
  
  // Realtime channel prefix for remote control
  static const String channelPrefix = 'remote:';
}
