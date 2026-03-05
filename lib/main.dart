import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:redpdf_tools/firebase_options.dart';
import '../providers/pdf_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import 'screens/navigation.dart';
import 'package:redpdf_tools/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isFirebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseInitialized = true;
  } catch (e) {
    log('⚠️ Firebase initialization failed: $e');
    log(
      '⚠️ Please ensure google-services.json (Android) or GoogleService-Info.plist (iOS) is added to your project. App starting in guest-only mode.',
    );
  }

  if (!isFirebaseInitialized) {
    log(
      'ℹ️ Firebase is not connected. Authentication features will be disabled.',
    );
  }

  // Initialize Repositories
  // final authRepository = FirebaseAuthRepository();
  // final userRepository = FirebaseUserRepository();

  runApp(
    MultiProvider(
      providers: [
        // Provider<AuthRepository>.value(value: authRepository),
        // Provider<UserRepository>.value(value: userRepository),
        // ChangeNotifierProvider(
        //   create: (_) => AuthProvider(authRepository, userRepository),
        // ),
        ChangeNotifierProvider(create: (_) => PdfProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer
    //2
    <
      ThemeProvider
      //, AuthProvider
    >(
      builder:
          (
            context,
            themeProvider,
            //authProvider,
            child,
          ) {
            return MaterialApp(
              title: 'RedPdf',
              debugShowCheckedModeBanner: false,
              themeMode: themeProvider.themeMode,
              theme: AppTheme.lightMode,
              darkTheme: AppTheme.darkMode,
              home: const Navigation(),
            );
          },
    );
  }
}
