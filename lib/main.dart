import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Data locale Indonesia untuk format tanggal (nama hari & bulan).
  await initializeDateFormatting('id', null);
  Intl.defaultLocale = 'id';
  runApp(const MatchaboyApp());
}

/// Warna benih tema hijau matcha (Material 3).
const Color kMatchaSeed = Color(0xFF6C8C3C);

class MatchaboyApp extends StatelessWidget {
  const MatchaboyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: kMatchaSeed);

    return MaterialApp(
      title: 'Matchaboy POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F8F0),
        appBarTheme: const AppBarTheme(centerTitle: true),
        cardTheme: CardThemeData(
          elevation: 0,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
