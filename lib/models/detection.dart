import 'dart:ui';

/// Satu hasil deteksi mentah dari model YOLOv8 pada foto tangkapan.
///
/// [className] sama persis dengan label kelas model (huruf kecil), dipakai
/// untuk lookup produk lewat `product_code`. [boundingBox] adalah kotak
/// **ternormalisasi** (semua nilai 0.0–1.0 relatif terhadap ukuran foto),
/// sehingga bisa langsung diskalakan ke ukuran tampilan saat menggambar kotak
/// di layar Hasil Deteksi tanpa perlu tahu dimensi piksel asli.
///
/// Pemetaan `YOLOResult` → [Detection] dan agregasi jumlah per varian
/// ditangani oleh `detection_service`.
class Detection {
  final String className;
  final double confidence;
  final Rect? boundingBox;

  const Detection({
    required this.className,
    required this.confidence,
    this.boundingBox,
  });
}
