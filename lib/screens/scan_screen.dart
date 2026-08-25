import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../models/detection.dart';
import '../services/detection_service.dart';
import '../widgets/detection_overlay.dart';
import 'detection_result_screen.dart';

/// Scan (Mode Kasir) — deteksi **real-time**: kotak + label digambar langsung
/// di atas live preview tiap frame begitu ada cup matcha terlihat (bukan
/// menunggu jepret). Deteksi live juga meng-*gate* tombol jepret (aktif saat
/// ada cup terdeteksi). Saat dijepret, frame dibekukan & hasil deteksi
/// diteruskan ke layar Hasil Deteksi untuk diproses jadi pesanan.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final YOLOViewController _controller = YOLOViewController();

  bool _checking = true;
  bool _permissionGranted = false;
  bool _capturing = false;

  List<YOLOResult> _latest = const [];
  Size? _frameSize;

  // Ambang keyakinan tetap (tidak diatur user).
  final double _threshold = kDefaultConfidenceThreshold;

  @override
  void initState() {
    super.initState();
    // Matikan overlay bawaan plugin; kita gambar sendiri agar label selalu
    // terbaca. Nilai ini diingat & diterapkan saat view siap.
    _controller.setShowOverlays(false);
    _requestCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _permissionGranted = status.isGranted;
      _checking = false;
    });
  }

  /// Deteksi yang lolos ambang saat ini (dipakai untuk gate tombol + hasil).
  List<YOLOResult> get _filtered =>
      _latest.where((r) => r.confidence >= _threshold).toList();

  /// Deteksi live yang sudah dipetakan ke [Detection] untuk digambar sebagai
  /// kotak real-time di atas preview (warna/label per varian dari overlay
  /// aplikasi, bukan overlay bawaan plugin).
  List<Detection> get _liveDetections => _filtered
      .map(
        (r) => Detection(
          className: r.className,
          confidence: r.confidence,
          boundingBox: r.normalizedBox,
        ),
      )
      .toList();

  void _onStreaming(Map<String, dynamic> data) {
    if (!mounted) return;
    final rawList = data['detections'];
    final results = <YOLOResult>[];
    if (rawList is List) {
      for (final d in rawList) {
        if (d is Map &&
            d['className'] != null &&
            d['confidence'] != null &&
            d['normalizedBox'] != null) {
          try {
            results.add(YOLOResult.fromMap(d));
          } catch (_) {
            // Lewati deteksi yang gagal di-parse.
          }
        }
      }
    }
    final w = (data['imageWidth'] as num?)?.toDouble();
    final h = (data['imageHeight'] as num?)?.toDouble();
    setState(() {
      _latest = results;
      if (w != null && h != null && w > 0 && h > 0) {
        _frameSize = Size(w, h);
      }
    });
  }

  Future<void> _capture() async {
    if (_capturing || _filtered.isEmpty) return;
    setState(() => _capturing = true);
    try {
      // Ambil frame mentah (tanpa overlay native — overlay kita gambar sendiri
      // di layar Hasil Deteksi).
      final bytes = await _controller.capturePhoto(withOverlays: false);
      final result = await DetectionService.instance.buildResult(
        results: _latest,
        imageBytes: bytes,
        frameSize: _frameSize,
        confidenceThreshold: _threshold,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetectionResultScreen(result: result)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cara memindai'),
        content: const Text(
          '1. Arahkan kamera ke tray berisi cup matcha.\n'
          '2. Kotak & label akan muncul otomatis di tiap cup yang terdeteksi.\n'
          '3. Setelah muncul, tombol jepret aktif — tekan untuk membekukan '
          'hasil dan lanjut ke ringkasan pesanan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_checking) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (!_permissionGranted) return _permissionDenied();

    return Stack(
      fit: StackFit.expand,
      children: [
        YOLOView(
          modelPath: kModelAssetPath,
          task: YOLOTask.detect,
          controller: _controller,
          confidenceThreshold: _threshold,
          onStreamingData: _onStreaming,
        ),
        // Kotak deteksi real-time di atas live preview. IgnorePointer agar
        // overlay tak pernah menghalangi gestur preview / tombol jepret.
        IgnorePointer(
          child: DetectionOverlay(
            detections: _liveDetections,
            frameSize: _frameSize,
            fit: BoxFit.cover,
          ),
        ),
        _viewfinder(),
        _topBar(),
        _bottomPanel(),
        if (_capturing) _capturingOverlay(),
      ],
    );
  }

  Widget _viewfinder() {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.82,
        heightFactor: 0.5,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white54, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    // Tempel ke atas; tanpa Align, bar mengisi seluruh tinggi Stack sehingga
    // tombolnya ter-center vertikal.
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circleIcon(Icons.arrow_back, () => Navigator.of(context).pop()),
              _circleIcon(Icons.help_outline, _showHelp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }

  Widget _bottomPanel() {
    final count = _filtered.length;
    final ready = count > 0;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ready
                    ? '$count cup terdeteksi — siap dijepret'
                    : 'Arahkan kamera ke cup matcha…',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 12),
              _captureButton(ready),
            ],
          ),
        ),
      ),
    );
  }

  Widget _captureButton(bool ready) {
    return GestureDetector(
      onTap: (ready && !_capturing) ? _capture : null,
      child: Opacity(
        opacity: ready ? 1.0 : 0.4,
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white24,
            border: Border.all(color: Colors.white, width: 5),
          ),
          child: Center(
            child: Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(Icons.camera_alt, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _capturingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Memproses…',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, color: Colors.white, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Aplikasi butuh izin kamera untuk memindai cup matcha.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: openAppSettings,
              child: const Text('Buka Pengaturan'),
            ),
            TextButton(
              onPressed: _requestCamera,
              child: const Text(
                'Coba lagi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
