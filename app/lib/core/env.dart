class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const hostAddress = String.fromEnvironment('HOST_ADDRESS');
  static const authToken = String.fromEnvironment('AUTH_TOKEN');
  static const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const redirectUrl = String.fromEnvironment('REDIRECT_URL');
}