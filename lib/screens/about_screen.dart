import 'package:flutter/material.dart';

import '../widgets/matcha_cup_icon.dart';

/// Tentang Aplikasi — info aplikasi, versi, deskripsi, kredit pengembang.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Versi ditampilkan statis (offline). Selaraskan dengan `version` di
  // pubspec.yaml bila dinaikkan.
  static const String _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang Aplikasi')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: MatchaCupIcon(size: 52, color: scheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Matchaboy POS',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versi $_version',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Deskripsi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aplikasi kasir (POS) untuk kedai Matchaboy AAR. '
                    'Mendeteksi varian & jumlah cup matcha dari kamera '
                    'menggunakan model YOLOv8 on-device, menghitung total '
                    'dari harga di basis data lokal, lalu menyimpan '
                    'transaksi. Seluruh proses berjalan offline.',
                    style: TextStyle(height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.storefront, color: scheme.primary),
                  title: const Text('Kedai'),
                  subtitle: const Text('Matchaboy AAR'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.memory, color: scheme.primary),
                  title: const Text('Model deteksi'),
                  subtitle: const Text('YOLOv8 (6 varian) • on-device'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.code, color: scheme.primary),
                  title: const Text('Pengembang'),
                  subtitle: const Text('Axa Rajandrya'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© 2026 Axa Rajandrya',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
