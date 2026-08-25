// Tes ringan yang tidak butuh plugin (kamera/DB/model), sehingga bisa jalan di
// lingkungan `flutter test` biasa.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:matchaboy_pos/screens/about_screen.dart';
import 'package:matchaboy_pos/utils/formatters.dart';

void main() {
  group('formatRupiah', () {
    test('format ribuan dengan pemisah titik', () {
      expect(formatRupiah(20000), 'Rp 20.000');
      expect(formatRupiah(18000), 'Rp 18.000');
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(1500000), 'Rp 1.500.000');
    });

    test('menangani nilai negatif', () {
      expect(formatRupiah(-5000), 'Rp -5.000');
    });
  });

  testWidgets('AboutScreen menampilkan nama & versi aplikasi', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Matchaboy POS'), findsOneWidget);
    expect(find.text('Versi 1.0.0'), findsOneWidget);
    expect(find.text('Matchaboy AAR'), findsOneWidget);
  });
}
