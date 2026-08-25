import 'package:flutter/material.dart';

import '../widgets/matcha_cup_icon.dart';
import 'dashboard_screen.dart';

/// Splash singkat. Memulai pemuatan model YOLO di *background* (sekali saja)
/// lalu berpindah ke Dashboard — navigasi tidak menunggu model selesai.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Model dimuat oleh YOLOView (native) saat layar Scan dibuka.
    _goToDashboard();
  }

  Future<void> _goToDashboard() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cup putih di atas hijau — sama persis dengan ikon HP & splash
            // native, agar transisi splash mulus & logo konsisten.
            MatchaCupIcon(size: 120, color: scheme.onPrimary),
            const SizedBox(height: 20),
            Text(
              'Matchaboy POS',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Matchaboy AAR',
              style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: scheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
