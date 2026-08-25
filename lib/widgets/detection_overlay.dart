import 'package:flutter/material.dart';

import '../models/detection.dart';

/// Nama tampilan per label kelas model (huruf kecil = product_code).
const Map<String, String> kVariantDisplayNames = {
  'og': 'Original',
  'vanilla': 'Vanilla',
  'choko': 'Choco',
  'taro': 'Taro',
  'pistachio': 'Pistachio',
  'red_velvet': 'Red Velvet',
};

/// Warna per varian — dipilih cukup gelap/pekat agar teks putih di atasnya
/// selalu terbaca, dan tiap varian mudah dibedakan.
const Map<String, Color> kVariantColors = {
  'og': Color(0xFF6D4C41), // coklat
  'vanilla': Color(0xFFEF6C00), // oranye tua
  'choko': Color(0xFF4E342E), // coklat tua
  'taro': Color(0xFF7B1FA2), // ungu
  'pistachio': Color(0xFF2E7D32), // hijau tua
  'red_velvet': Color(0xFFC62828), // merah
};

const Color kDefaultDetectionColor = Color(0xFF37474F); // biru keabuan tua

/// Menggambar kotak deteksi + label yang **selalu terbaca** (teks putih di atas
/// pil berwarna pekat), menggantikan overlay bawaan plugin yang warnanya tak
/// bisa diatur.
///
/// [frameSize] = dimensi frame sumber (imageWidth/imageHeight dari YOLOView);
/// [fit] = cara frame ditampilkan (cover untuk live preview, contain untuk
/// foto hasil), dipakai untuk memetakan kotak ternormalisasi ke area layar.
class DetectionOverlay extends StatelessWidget {
  final List<Detection> detections;
  final Size? frameSize;
  final BoxFit fit;

  const DetectionOverlay({
    super.key,
    required this.detections,
    required this.frameSize,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _DetectionPainter(
            detections: detections,
            frameSize: frameSize,
            fit: fit,
          ),
        );
      },
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final List<Detection> detections;
  final Size? frameSize;
  final BoxFit fit;

  _DetectionPainter({
    required this.detections,
    required this.frameSize,
    required this.fit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final frame = frameSize;
    if (frame == null ||
        frame.width <= 0 ||
        frame.height <= 0 ||
        detections.isEmpty) {
      return;
    }
    canvas.clipRect(Offset.zero & size);

    final scaleW = size.width / frame.width;
    final scaleH = size.height / frame.height;
    final scale = fit == BoxFit.cover
        ? (scaleW > scaleH ? scaleW : scaleH)
        : (scaleW < scaleH ? scaleW : scaleH);
    final dispW = frame.width * scale;
    final dispH = frame.height * scale;
    final dx = (size.width - dispW) / 2;
    final dy = (size.height - dispH) / 2;

    for (final d in detections) {
      final box = d.boundingBox;
      if (box == null) continue;
      final color = kVariantColors[d.className] ?? kDefaultDetectionColor;

      final rect = Rect.fromLTRB(
        dx + box.left * dispW,
        dy + box.top * dispH,
        dx + box.right * dispW,
        dy + box.bottom * dispH,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = color,
      );

      final name = kVariantDisplayNames[d.className] ?? d.className;
      _paintLabel(
        canvas,
        '$name ${(d.confidence * 100).toStringAsFixed(0)}%',
        color,
        rect,
        size,
      );
    }
  }

  void _paintLabel(
    Canvas canvas,
    String text,
    Color color,
    Rect box,
    Size size,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const padH = 7.0;
    const padV = 4.0;
    final pillW = tp.width + padH * 2;
    final pillH = tp.height + padV * 2;

    // Tempatkan di atas kotak; kalau mentok atas, taruh di dalam kotak.
    var left = box.left;
    if (left + pillW > size.width) left = size.width - pillW;
    if (left < 0) left = 0;
    var top = box.top - pillH - 2;
    if (top < 0) top = box.top + 2;

    final pill = Rect.fromLTWH(left, top, pillW, pillH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pill, const Radius.circular(6)),
      Paint()..color = color,
    );
    tp.paint(canvas, Offset(left + padH, top + padV));
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter old) =>
      old.detections != detections ||
      old.frameSize != frameSize ||
      old.fit != fit;
}
