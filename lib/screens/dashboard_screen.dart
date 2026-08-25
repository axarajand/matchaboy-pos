import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../utils/formatters.dart';
import '../widgets/matcha_cup_icon.dart';
import 'about_screen.dart';
import 'history_screen.dart';
import 'product_management_screen.dart';
import 'scan_screen.dart';

/// Dashboard — pusat navigasi. Header sapaan, ringkasan harian, dan empat
/// tombol (Scan paling menonjol).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, int>> _summary;

  @override
  void initState() {
    super.initState();
    _summary = DatabaseService.instance.getDailySummary();
  }

  void _reloadSummary() {
    setState(() {
      _summary = DatabaseService.instance.getDailySummary();
    });
  }

  /// Buka halaman lalu segarkan ringkasan saat kembali (data mungkin berubah).
  Future<void> _open(Widget page) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) _reloadSummary();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reloadSummary(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(scheme),
              const SizedBox(height: 16),
              _summaryCard(scheme),
              const SizedBox(height: 24),
              _scanButton(scheme),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _menuButton(
                      icon: Icons.receipt_long,
                      label: 'Riwayat\nTransaksi',
                      onTap: () => _open(const HistoryScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _menuButton(
                      icon: Icons.inventory_2,
                      label: 'Manajemen\nProduk',
                      onTap: () => _open(const ProductManagementScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _menuButton(
                icon: Icons.info_outline,
                label: 'Tentang Aplikasi',
                onTap: () => _open(const AboutScreen()),
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ColorScheme scheme) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: MatchaCupIcon(size: 34, color: scheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_greeting, style: const TextStyle(fontSize: 14)),
            const Text(
              'Matchaboy AAR',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, int>>(
          future: _summary,
          builder: (context, snapshot) {
            final data = snapshot.data;
            final count = data?['transaction_count'] ?? 0;
            final revenue = data?['revenue'] ?? 0;
            final loading =
                snapshot.connectionState == ConnectionState.waiting;
            return Row(
              children: [
                Expanded(
                  child: _summaryItem(
                    icon: Icons.point_of_sale,
                    label: 'Transaksi hari ini',
                    value: loading ? '…' : '$count',
                    scheme: scheme,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: scheme.outlineVariant,
                ),
                Expanded(
                  child: _summaryItem(
                    icon: Icons.payments,
                    label: 'Pendapatan hari ini',
                    value: loading ? '…' : formatRupiah(revenue),
                    scheme: scheme,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme scheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _scanButton(ColorScheme scheme) {
    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(const ScanScreen()),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          child: Column(
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 64,
                color: scheme.onPrimary,
              ),
              const SizedBox(height: 12),
              Text(
                'Scan Pesanan',
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Arahkan kamera ke tray matcha',
                style: TextStyle(
                  color: scheme.onPrimary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: fullWidth
              ? Row(
                  children: [
                    Icon(icon, color: scheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Icon(icon, color: scheme.primary, size: 32),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
