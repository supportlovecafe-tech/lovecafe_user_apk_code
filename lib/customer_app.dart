import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/customer_router.dart';
import 'core/providers/theme_provider.dart';

class CinemaEatsCustomerApp extends ConsumerWidget {
  const CinemaEatsCustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'CinemaEats Consumer',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: customerRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
