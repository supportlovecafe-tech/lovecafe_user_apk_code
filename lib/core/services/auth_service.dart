import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<Map<String, dynamic>> signUpWithPhone({
    required String phone,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    try {
      // 1. Try real signup first (in case it's enabled in future)
      final response = await client.auth.signUp(
        phone: phone,
        password: password,
        data: data,
      );
      return {'user': response.user, 'session': response.session};
    } catch (e) {
      // 2. Demo Bypass: Store in customer_profiles directly
      final existing = await client
          .from('customer_profiles')
          .select()
          .eq('phone', phone)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Phone number already registered');
      }

      final profile = {
        'phone': phone,
        'password': password,
        'first_name': data['first_name'],
        'last_name': data['last_name'],
        'email': data['email'],
      };

      final newProfile = await client
          .from('customer_profiles')
          .insert(profile)
          .select()
          .single();
      
      return {'demo_user': newProfile};
    }
  }

  Future<Map<String, dynamic>> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      // 1. Try real login first
      final response = await client.auth.signInWithPassword(
        phone: phone,
        password: password,
      );
      return {'user': response.user, 'session': response.session};
    } catch (e) {
      // 2. Demo Bypass: Check customer_profiles
      final profile = await client
          .from('customer_profiles')
          .select()
          .eq('phone', phone)
          .eq('password', password)
          .maybeSingle();

      if (profile == null) {
        throw Exception('Invalid phone number or password');
      }

      return {'demo_user': profile};
    }
  }

  Future<void> sendPhoneOtp(String phone) async {
    await client.auth.signInWithOtp(phone: phone);
  }

  Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    return await client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  Future<void> sendEmailOtp(String email) async {
    await client.auth.signInWithOtp(email: email);
  }

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    return await client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) return;
    await client.from('profiles').update(data).eq('id', user.id);
  }

  Future<void> updateCustomerProfile(String profileId, Map<String, dynamic> data) async {
    await client.from('customer_profiles').update(data).eq('id', profileId);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<bool> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(OAuthProvider.google);
  }

  bool get isAuthenticated => currentUser != null;
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
