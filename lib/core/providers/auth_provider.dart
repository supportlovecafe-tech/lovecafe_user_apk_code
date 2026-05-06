import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'cart_provider.dart';
import 'seat_selection_provider.dart';
import 'orders_provider.dart';
import 'loyalty_provider.dart';
import 'notification_provider.dart';
import 'menu_provider.dart';



enum AuthStatus { AUTHENTICATED, GUEST, UNAUTHENTICATED }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? userName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  final bool isDemo;

  AuthState({
    required this.status,
    this.userId,
    this.userName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.isDemo = false,
  });

  factory AuthState.unauthenticated() => AuthState(status: AuthStatus.UNAUTHENTICATED);
  factory AuthState.authenticated({
    required String id, 
    String? email,
    String? userName,
    String? phone,
    String? avatarUrl,
    bool isDemo = false,
  }) => 
    AuthState(
      status: AuthStatus.AUTHENTICATED, 
      userId: id, 
      email: email,
      userName: userName,
      phone: phone,
      avatarUrl: avatarUrl,
      isDemo: isDemo,
    );

  Map<String, dynamic> toMap() {
    return {
      'status': status.index,
      'userId': userId,
      'userName': userName,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'isDemo': isDemo,
    };
  }

  factory AuthState.fromMap(Map<String, dynamic> map) {
    return AuthState(
      status: AuthStatus.values[map['status']],
      userId: map['userId'],
      userName: map['userName'],
      email: map['email'],
      phone: map['phone'],
      avatarUrl: map['avatarUrl'],
      isDemo: map['isDemo'] ?? false,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  static const String _storageKey = 'ce_auth_state';

  AuthNotifier(this._ref) : super(AuthState.unauthenticated()) {
    _listenToAuthChanges();
    restoreSession();
  }

  void _listenToAuthChanges() {
    _ref.read(authServiceProvider).authStateChanges.listen((event) {
      final user = event.session?.user;
      if (user != null) {
        state = AuthState.authenticated(
          id: user.id,
          email: user.email,
        );
        _persistState();
      } else if (!state.isDemo && state.status == AuthStatus.AUTHENTICATED) {
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
    await _ref.read(authServiceProvider).signInWithGoogle();
  }

  Future<void> signIn(String phone, String password) async {
    final cleanPhone = phone.trim();
    
    final result = await _ref.read(authServiceProvider).signInWithPhone(phone: cleanPhone, password: password);
    
    if (result.containsKey('demo_user')) {
      final user = result['demo_user'] as Map<String, dynamic>;
      state = AuthState.authenticated(
        id: user['id'].toString(),
        phone: user['phone'],
        userName: '${user['first_name']} ${user['last_name']}',
        email: user['email'],
        avatarUrl: user['avatar_url'],
        isDemo: true,
      );
      _persistState();
    }
    // If it's a real user, the listener _listenToAuthChanges will handle it
  }

  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    required String password,
  }) async {
    final result = await _ref.read(authServiceProvider).signUpWithPhone(
      phone: phone,
      password: password,
      data: {
        'role': 'CUSTOMER',
        'first_name': firstName,
        'last_name': lastName,
        'full_name': '$firstName $lastName',
        if (email != null) 'email': email,
      },
    );

    if (result.containsKey('demo_user')) {
      final user = result['demo_user'] as Map<String, dynamic>;
      state = AuthState.authenticated(
        id: user['id'].toString(),
        phone: user['phone'],
        userName: '${user['first_name']} ${user['last_name']}',
        email: user['email'],
        isDemo: true,
      );
      _persistState();
    }
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? avatarUrl,
  }) async {
    final Map<String, dynamic> data = {};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (firstName != null || lastName != null) {
      data['full_name'] = '${firstName ?? state.userName?.split(' ')[0] ?? ''} ${lastName ?? state.userName?.split(' ').skip(1).join(' ') ?? ''}'.trim();
    }
    if (email != null) data['email'] = email;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    if (state.isDemo) {
      await _ref.read(authServiceProvider).updateCustomerProfile(state.userId!, data);
    } else {
      await _ref.read(authServiceProvider).updateProfile(data);
    }
    
    // Update local state
    state = AuthState.authenticated(
      id: state.userId!,
      email: email ?? state.email,
      userName: data['full_name'] ?? state.userName,
      phone: state.phone,
      avatarUrl: avatarUrl ?? state.avatarUrl,
      isDemo: state.isDemo,
    );
    _persistState();
  }

  Future<void> requestPhoneOtp(String phone) async {
    await _ref.read(authServiceProvider).sendPhoneOtp(phone);
  }

  Future<bool> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      await _ref.read(authServiceProvider).verifyPhoneOtp(phone: phone, token: otp);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    // 1. Sign out from the backend auth service
    await _ref.read(authServiceProvider).signOut();
    
    // 2. FULL STORAGE CLEAR (The Flutter equivalent of AsyncStorage.clear())
    // This wipes all persistent data including cart, cinema selection, and session tokens.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    
    // 3. Reset Global State (Update auth status to UNAUTHENTICATED)
    state = AuthState.unauthenticated();
    
    // 4. PURGE ALL IN-MEMORY STATE (Riverpod Invalidation)
    // This forces all user-specific providers to dispose and recreate with fresh state.
    _ref.invalidate(cartProvider);
    _ref.invalidate(seatSelectionProvider);
    _ref.invalidate(ordersProvider);
    _ref.invalidate(loyaltyProvider);
    _ref.invalidate(notificationProvider);
    _ref.invalidate(menuProvider);
    
    // 5. Re-persist the clean unauthenticated state
    _persistState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
