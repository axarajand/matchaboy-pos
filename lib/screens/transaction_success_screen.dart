import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../utils/formatters.dart';
import 'scan_screen.dart';

/// Transaksi Sukses — konfirmasi penyimpanan: centang hijau, kode transaksi,
/// total. Tombol "Transaksi Baru" (→ Scan) & "Kembali ke Beranda".
class TransactionSuccessScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionSuccessScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Transaksi Berhasil!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Transaksi telah disimpan.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _row('Kode', transaction.transactionCode),
                      const Divider(height: 24),
                      _row('Jumlah item', '${transaction.totalItems}'),
                      const Divider(height: 24),
                      _row(
                        'Total',
                        formatRupiah(transaction.totalAmount),
                        emphasize: true,
                        scheme: scheme,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const ScanScreen()),
                  );
                },
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Transaksi Baru'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Kembali ke Beranda'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool emphasize = false,
    ColorScheme? scheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 20 : 15,
            fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
            color: emphasize ? scheme?.primary : null,
          ),
        ),
      ],
    );
  }
}
