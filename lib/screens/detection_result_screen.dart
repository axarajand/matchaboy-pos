import 'package:flutter/material.dart';

import '../services/detection_service.dart';
import '../utils/formatters.dart';
import '../widgets/detection_overlay.dart';
import 'confirm_transaction_screen.dart';

/// Hasil Deteksi — snapshot frame (bounding box sudah tergambar dari overlay
/// native) di atas, daftar varian (card), total, tombol "Ulangi" &
/// "Lanjutkan".
class DetectionResultScreen extends StatelessWidget {
  final ScanResult result;

  const DetectionResultScreen({super.key, required this.result});

  void _continue(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfirmTransactionScreen(items: result.items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Deteksi')),
      body: Column(
        children: [
          _photo(),
          if (result.unmatchedClasses.isNotEmpty) _unmatchedBanner(context),
          Expanded(child: _variantList(context)),
          _bottomBar(context),
        ],
      ),
    );
  }

  Widget _photo() {
    return Container(
      color: Colors.black,
      height: 300,
      width: double.infinity,
      alignment: Alignment.center,
      child: result.imageBytes == null
          ? const Icon(Icons.image_not_supported, color: Colors.white38, size: 48)
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(result.imageBytes!, fit: BoxFit.contain),
                DetectionOverlay(
                  detections: result.detections,
                  frameSize: result.frameSize,
                  fit: BoxFit.contain,
                ),
              ],
            ),
    );
  }

  Widget _unmatchedBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.errorContainer,
      padding: const EdgeInsets.all(12),
      child: Text(
        'Varian tak dikenal (tak ada di produk): '
        '${result.unmatchedClasses.join(', ')}',
        style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
      ),
    );
  }

  Widget _variantList(BuildContext context) {
    if (result.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Tidak ada cup matcha terdeteksi.\nCoba ulangi pemindaian.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: result.items.length,
      itemBuilder: (context, index) {
        final item = result.items[index];
        final scheme = Theme.of(context).colorScheme;
        final confidence = item.confidenceScore == null
            ? ''
            : ' • ${(item.confidenceScore! * 100).toStringAsFixed(0)}%';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Text(
                '${item.quantity}',
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              item.productName ?? item.productCode ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${item.quantity} × ${formatRupiah(item.unitPrice)}$confidence',
            ),
            trailing: Text(
              formatRupiah(item.subtotal),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        );
      },
    );
  }

  Widget _bottomBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 16)),
                  Text(
                    formatRupiah(result.totalAmount),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Ulangi'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: result.isEmpty ? null : () => _continue(context),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Lanjutkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
