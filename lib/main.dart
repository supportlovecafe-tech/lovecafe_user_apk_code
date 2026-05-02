import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_app.dart';
import 'core/services/backend_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (BackendConfig.isSupabaseConfigured) {
      await Supabase.initialize(
        url: BackendConfig.supabaseUrl,
        anonKey: BackendConfig.supabaseAnonKey,
      );
    }
  } catch (e) {
    print('Supabase init failed: $e');
  }
  runApp(
    const ProviderScope(
      child: CinemaEatsCustomerApp(),
    ),
  );
}
