import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../models/detection.dart';
import '../models/transaction_item.dart';
import 'database_service.dart';

/// Ambang keyakinan default sesuai CLAUDE.md (bisa diatur user via slider).
const double kDefaultConfidenceThreshold = 0.5;

/// Path aset model — JANGAN diubah/rename/re-export (lihat CLAUDE.md).
const String kModelAssetPath = 'assets/models/matcha.tflite';

/// Hasil satu kali pemindaian: snapshot foto (sudah ada bounding box dari
/// overlay native) + item ter-agregasi per varian yang sudah dipetakan ke
/// harga produk.
class ScanResult {
  /// JPEG frame kamera saat capture, sudah dikomposit dengan kotak deteksi
  /// (dari `capturePhoto(withOverlays: true)`). Bisa null bila capture gagal.
  final Uint8List? imageBytes;

  /// Deteksi mentah (sudah disaring ambang) — disimpan untuk audit/keperluan
  /// lanjutan; kotak tidak digambar ulang di UI karena sudah ada di foto.
  final List<Detection> detections;

  /// Satu item per varian terdeteksi; `quantity` = jumlah cup,
  /// `confidenceScore` = rata-rata keyakinan. Sudah dipetakan ke produk.
  final List<TransactionItem> items;

  /// Label kelas terdeteksi yang tidak punya produk padanan di DB.
  final List<String> unmatchedClasses;

  /// Dimensi frame sumber (imageWidth/imageHeight) untuk memetakan kotak
  /// ternormalisasi ke foto saat menggambar overlay di Hasil Deteksi.
  final Size? frameSize;

  const ScanResult({
    required this.imageBytes,
    required this.detections,
    required this.items,
    required this.unmatchedClasses,
    required this.frameSize,
  });

  int get totalCups => items.fold(0, (sum, i) => sum + i.quantity);
  int get totalAmount => items.fold(0, (sum, i) => sum + i.subtotal);
  bool get isEmpty => items.isEmpty;
}

/// Mengubah hasil deteksi live YOLO (`YOLOResult` dari `YOLOView`) menjadi
/// [ScanResult]: saring ambang → agregasi jumlah per varian → lookup harga
/// via `getProductByCode`. Model dimuat & dijalankan oleh `YOLOView` (native),
/// jadi layanan ini murni agregasi + pemetaan ke produk. Semua offline.
class DetectionService {
  DetectionService._internal();
  static final DetectionService instance = DetectionService._internal();

  final DatabaseService _db = DatabaseService.instance;

  /// Bangun [ScanResult] dari daftar deteksi live saat tombol jepret ditekan.
  Future<ScanResult> buildResult({
    required List<YOLOResult> results,
    Uint8List? imageBytes,
    Size? frameSize,
    double confidenceThreshold = kDefaultConfidenceThreshold,
  }) async {
    final filtered = results
        .where((r) => r.confidence >= confidenceThreshold)
        .toList();

    final detections = filtered
        .map(
          (r) => Detection(
            className: r.className,
            confidence: r.confidence,
            boundingBox: r.normalizedBox,
          ),
        )
        .toList();

    // Agregasi jumlah cup per className (varian).
    final grouped = <String, List<YOLOResult>>{};
    for (final r in filtered) {
      grouped.putIfAbsent(r.className, () => []).add(r);
    }

    final items = <TransactionItem>[];
    final unmatched = <String>[];
    for (final entry in grouped.entries) {
      final product = await _db.getProductByCode(entry.key);
      if (product == null || product.productId == null) {
        unmatched.add(entry.key);
        continue;
      }
      final quantity = entry.value.length;
      final avgConfidence =
          entry.value.map((r) => r.confidence).reduce((a, b) => a + b) /
          quantity;
      items.add(
        TransactionItem.forProduct(
          product,
          quantity: quantity,
          confidenceScore: avgConfidence,
        ),
      );
    }
    items.sort((a, b) => (a.productName ?? '').compareTo(b.productName ?? ''));

    return ScanResult(
      imageBytes: imageBytes,
      detections: detections,
      items: items,
      unmatchedClasses: unmatched,
      frameSize: frameSize,
    );
  }
}
