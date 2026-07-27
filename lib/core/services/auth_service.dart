import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final AuthResponse response = await client.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.recovery,
    );

    if (response.session == null) {
      throw Exception('Invalid OTP or session expired.');
    }

    await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) return;
    
    // We update customer_profiles using the current auth user ID
    await client.from('customer_profiles').update(data).eq('id', user.id);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<bool> signInWithGoogle() async {
    // TODO: Replace with your actual Web Client ID from Google Cloud Console
      const webClientId = '507519544150-hvfj5iga0sinfv7t9j6oqqvhcggjrn8d.apps.googleusercontent.com';
    // TODO: Replace with your actual iOS Client ID from Google Cloud Console (if supporting iOS)
    const iosClientId = '507519544150-1jkcfca4sflvavsnlihkm5bidipupvrl.apps.googleusercontent.com';

    try {
      String? platformClientId;
      if (kIsWeb) {
        platformClientId = webClientId;
      } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        platformClientId = iosClientId;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
        clientId: platformClientId,
      );
      
      // Force account picker to show by signing out of any cached sessions first
      await googleSignIn.signOut();
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return false; // User canceled the sign-in
      }
      
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'Missing Google Auth Token';
      }

      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      return response.session != null;
    } catch (e) {
      print('Google sign-in error: $e');
      throw Exception('Google sign-in error: $e');
    }
  }

  bool get isAuthenticated => currentUser != null;

  // --- Phone OTP Registration & Login Flow ---

  Future<void> sendOtp(String phone) async {
    final response = await client.functions.invoke('dummy', headers: {}); // Just to get the structure if we used edge functions, but we are using our custom Next.js backend
    // Since we are using Next.js backend, we use standard http
    // Let's use standard http package or simply assume the caller handles http for sendOtp like in Checkout
    // Wait, it's better to implement it here for reusability, but we need the backend URL.
    // Instead of adding http dependency to auth_service, let the caller (AuthNotifier or Screen) handle it
    // since the app already uses `http` in `checkout_screen.dart` with `BackendConfig.backendApiUrl`.
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
