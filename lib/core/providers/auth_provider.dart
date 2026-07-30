import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/backend_config.dart';
import '../services/auth_service.dart';
import 'cart_provider.dart';
import 'seat_selection_provider.dart';
import 'orders_provider.dart';
import 'loyalty_provider.dart';
import 'notification_provider.dart';
import 'menu_provider.dart';
import 'combo_provider.dart';
import 'reorder_provider.dart';

enum AuthStatus { AUTHENTICATED, GUEST, UNAUTHENTICATED }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? userName;
  final String? email;
  final String? avatarUrl;
  final String? phone;

  AuthState({
    required this.status,
    this.userId,
    this.userName,
    this.email,
    this.avatarUrl,
    this.phone,
  });

  factory AuthState.unauthenticated() => AuthState(status: AuthStatus.UNAUTHENTICATED);
  factory AuthState.authenticated({
    required String id, 
    String? email,
    String? userName,
    String? avatarUrl,
    String? phone,
  }) => 
    AuthState(
      status: AuthStatus.AUTHENTICATED, 
      userId: id, 
      email: email,
      userName: userName,
      avatarUrl: avatarUrl,
      phone: phone,
    );

  Map<String, dynamic> toMap() {
    return {
      'status': status.index,
      'userId': userId,
      'userName': userName,
      'email': email,
      'avatarUrl': avatarUrl,
      'phone': phone,
    };
  }

  factory AuthState.fromMap(Map<String, dynamic> map) {
    return AuthState(
      status: AuthStatus.values[map['status']],
      userId: map['userId'],
      userName: map['userName'],
      email: map['email'],
      avatarUrl: map['avatarUrl'],
      phone: map['phone'],
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  static const String _storageKey = 'ce_auth_state_v2';

  AuthNotifier(this._ref) : super(AuthState.unauthenticated()) {
    _listenToAuthChanges();
    restoreSession();
  }

  void _listenToAuthChanges() {
    _ref.read(authServiceProvider).authStateChanges.listen((event) async {
      final user = event.session?.user;
      if (user != null) {
        try {
          final client = _ref.read(authServiceProvider).client;
          var profile = await client
              .from('customer_profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();

          final String? firstName = profile?['first_name'];
          final String? lastName = profile?['last_name'];
          final String? fullName = profile?['full_name'] ?? 
              ((firstName != null || lastName != null) ? '${firstName ?? ''} ${lastName ?? ''}'.trim() : null);

          state = AuthState.authenticated(
            id: user.id,
            email: user.email ?? profile?['email'],
            userName: fullName,
            avatarUrl: profile?['avatar_url'] ?? user.userMetadata?['avatar_url'],
            phone: profile?['phone'] ?? user.phone,
          );
        } catch (e) {
          state = AuthState.authenticated(
            id: user.id,
            email: user.email,
            phone: user.phone,
          );
        }
        _persistState();
      } else if (state.status == AuthStatus.AUTHENTICATED) {
        state = AuthState.unauthenticated();
        _persistState();
      }
    });
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.status == AuthStatus.UNAUTHENTICATED) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(_storageKey, jsonEncode(state.toMap()));
    }
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved != null) {
      try {
        state = AuthState.fromMap(jsonDecode(saved));
      } catch (e) {
        print('Error restoring auth session: $e');
      }
    }
  }

  void loginAsGuest() {
    state = AuthState(status: AuthStatus.GUEST);
    _persistState();
  }

  Future<void> signInWithGoogle() async {
    final success = await _ref.read(authServiceProvider).signInWithGoogle();
    if (!success) {
      throw 'Google sign-in was canceled.';
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _ref.read(authServiceProvider).signInWithEmail(email: email.trim(), password: password);
  }

  Future<void> signUpWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> data = {
      'role': 'CUSTOMER',
      'first_name': firstName,
      'last_name': lastName,
      'full_name': '$firstName $lastName',
    };
    
    // If it's a proxy email, extract the phone number
    if (email.endsWith('@lovecafe.local')) {
      data['phone'] = email.split('@')[0];
    } else {
      data['email'] = email.trim(); // store real email in profile
    }

    await _ref.read(authServiceProvider).signUpWithEmail(
      email: email.trim(),
      password: password,
      data: data,
    );
  }

  Future<void> loginWithPhone({
    required String phone,
    required String otpCode,
    String? firstName,
    String? lastName,
  }) async {
    final baseUrl = BackendConfig.backendApiUrl;
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/phone-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'otpCode': otpCode,
        'firstName': firstName,
        'lastName': lastName,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Phone login failed');
    }

    final data = jsonDecode(response.body);
    final email = data['email'];
    final password = data['password'];

    // 2. Sign in with the returned proxy email and secure one-time password
    await signInWithEmail(email, password);
  }

  Future<void> resetPassword(String email) async {
    await _ref.read(authServiceProvider).sendPasswordResetEmail(email.trim());
  }

  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _ref.read(authServiceProvider).resetPasswordWithOtp(
      email: email.trim(),
      otp: otp.trim(),
      newPassword: newPassword,
    );
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? avatarUrl,
  }) async {
    final Map<String, dynamic> data = {};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (firstName != null || lastName != null) {
      data['full_name'] = '${firstName ?? state.userName?.split(' ')[0] ?? ''} ${lastName ?? state.userName?.split(' ').skip(1).join(' ') ?? ''}'.trim();
    }
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    await _ref.read(authServiceProvider).updateProfile(data);
    
    // Update local state
    state = AuthState.authenticated(
      id: state.userId!,
      email: state.email,
      userName: data['full_name'] ?? state.userName,
      avatarUrl: avatarUrl ?? state.avatarUrl,
      phone: state.phone,
    );
    _persistState();
  }

  Future<void> deleteAccount() async {
    await _ref.read(authServiceProvider).deleteAccount();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    state = AuthState.unauthenticated();
    
    _ref.invalidate(cartProvider);
    _ref.invalidate(seatSelectionProvider);
    _ref.invalidate(ordersProvider);
    _ref.invalidate(loyaltyProvider);
    _ref.invalidate(notificationProvider);
    _ref.invalidate(menuProvider);
    _ref.invalidate(comboProvider);
    _ref.invalidate(reorderProvider);
    
    _persistState();
  }

  Future<void> logout() async {
    await _ref.read(authServiceProvider).signOut();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    state = AuthState.unauthenticated();
    
    _ref.invalidate(cartProvider);
    _ref.invalidate(seatSelectionProvider);
    _ref.invalidate(ordersProvider);
    _ref.invalidate(loyaltyProvider);
    _ref.invalidate(notificationProvider);
    _ref.invalidate(menuProvider);
    _ref.invalidate(comboProvider);
    _ref.invalidate(reorderProvider);
    
    _persistState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
