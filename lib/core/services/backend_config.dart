class BackendConfig {
  // Hardcoded for development to ensure connectivity
  static const String _hardcodedUrl = 'https://pwbvoosqunrvqewokynz.supabase.co';
  static const String _hardcodedAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB3YnZvb3NxdW5ydnFld29reW56Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2OTQwMDksImV4cCI6MjA5MjI3MDAwOX0.Zk7zWSkDAQNwFGIhzwW4iZtfOlLT5OpwH1SW78T-BFU';

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: _hardcodedUrl);
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: _hardcodedAnonKey);
  static const String razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID');
  static const String adminPhoneList = String.fromEnvironment('ADMIN_PHONES');
  static const String backendApiUrl = String.fromEnvironment('BACKEND_API_URL', defaultValue: 'http://127.0.0.1:3001');

  static bool get isSupabaseConfigured {
    final configured = supabaseUrl.isNotEmpty && 
           supabaseUrl != 'https://your-project.supabase.co' &&
           supabaseAnonKey.isNotEmpty;
    if (!configured) {
      print('BackendConfig: Supabase URL or Anon Key is missing!');
    }
    return configured;
  }

  static bool get isRazorpayConfigured => razorpayKeyId.isNotEmpty;

  static List<String> get adminPhones => adminPhoneList
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();
}
