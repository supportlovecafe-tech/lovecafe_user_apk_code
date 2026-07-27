import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_app.dart';
import 'core/services/backend_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (BackendConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: BackendConfig.supabaseUrl,
      anonKey: BackendConfig.supabaseAnonKey,
    );
  }
  runApp(
    const ProviderScope(
      child: LoveCafeCustomerApp(),
    ),
  );
}
