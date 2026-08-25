import 'package:flutter/material.dart';

/// Ikon cup es matcha — **siluet solid** yang bentuknya identik dengan ikon
/// launcher / splash native (`android/.../drawable/ic_matcha_foreground.xml`),
/// supaya logo konsisten di seluruh aplikasi. Digambar satu warna ([color]);
/// warnanya menyesuaikan latar tempat ikon dipakai.
class MatchaCupIcon extends StatelessWidget {
  final double size;
  final Color color;

  const MatchaCupIcon({super.key, this.size = 28, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MatchaCupPainter(color)),
    );
  }
}

class _MatchaCupPainter extends CustomPainter {
  final Color color;

  _MatchaCupPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Path sama persis dengan vektor 108x108 di ic_matcha_foreground.xml.
    canvas.scale(size.width / 108.0, size.height / 108.0);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color
      ..isAntiAlias = true;

    // Tutup dome.
    final lid = Path()
      ..moveTo(30, 35)
      ..lineTo(78, 35)
      ..quadraticBezierTo(81, 35, 81, 38)
      ..lineTo(81, 45)
      ..quadraticBezierTo(81, 48, 78, 48)
      ..lineTo(30, 48)
      ..quadraticBezierTo(27, 48, 27, 45)
      ..lineTo(27, 38)
      ..quadraticBezierTo(27, 35, 30, 35)
      ..close();
    canvas.drawPath(lid, paint);

    // Sedotan.
    final straw = Path()
      ..moveTo(63, 43)
      ..lineTo(68, 43)
      ..lineTo(81, 22)
      ..lineTo(76, 20)
      ..close();
    canvas.drawPath(straw, paint);

    // Badan gelas.
    final body = Path()
      ..moveTo(30, 49)
      ..lineTo(78, 49)
      ..lineTo(72, 83)
      ..quadraticBezierTo(71.5, 86, 68, 86)
      ..lineTo(40, 86)
      ..quadraticBezierTo(36.5, 86, 36, 83)
      ..close();
    canvas.drawPath(body, paint);
  }

  @override
  bool shouldRepaint(covariant _MatchaCupPainter old) => old.color != color;
}
