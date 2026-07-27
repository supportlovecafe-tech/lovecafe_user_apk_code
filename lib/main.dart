import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_app.dart';
import 'core/services/backend_config.dart';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9), // Light clean background
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.coffee_maker_rounded, size: 64, color: Color(0xFFD4AF37)), // Gold/Cafe accent
                const SizedBox(height: 20),
                Text(
                  kReleaseMode 
                      ? 'Oops! Something went wrong at the cafe.\nOur engineers have been notified.' 
                      : details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

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
      child: LoveCafeCustomerApp(),
    ),
  );

  // Request App Tracking Transparency for iOS
  Future.delayed(const Duration(seconds: 1), () async {
    try {
      await AppTrackingTransparency.requestTrackingAuthorization();
    } catch (e) {
      print('ATT Request Failed: $e');
    }
  });
}
