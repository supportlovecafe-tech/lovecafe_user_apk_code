class BackendConfig {
  // Hardcoded for development to ensure connectivity
  static const String _hardcodedUrl = 'https://pwbvoosqunrvqewokynz.supabase.co';
  static const String _hardcodedAnonKey = 'sb_publishable_hiVcMsabjEaUOUOE1GNqQA_y30oYC8b';

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: _hardcodedUrl);
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: _hardcodedAnonKey);
  static const String razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID');
  static const String adminPhoneList = String.fromEnvironment('ADMIN_PHONES');
  static const String backendApiUrl = String.fromEnvironment('BACKEND_API_URL', defaultValue: 'http://localhost:3000');

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
