// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with a short timeout so the app doesn't hang
  // when the cloud project is paused or the device is offline.
  if (!kUseMockDatabase) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      ).timeout(const Duration(seconds: 4));
    } catch (_) {
      // Supabase unavailable – the app will fall back to mock data.
    }
  } else {
    // Still initialise so the Supabase singleton exists (some imports need it).
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  // AuthProvider starts in `initial` state; the SplashPage will call
  // restoreSession() after its animation, so don't block main() here.
  final authProvider = AuthProvider();
  final languageProvider = LanguageProvider(
    await SharedPreferences.getInstance(),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: languageProvider),
      ],
      child: const StaffPortalApp(),
    ),
  );
}

class StaffPortalApp extends StatelessWidget {
  const StaffPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final router = AppRouter.createRouter(authProvider);

    return MaterialApp.router(
      title: 'Food Angel Staff Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: languageProvider.locale,
      supportedLocales: const [Locale('en'), Locale('zh', 'HK')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    );
  }
}
