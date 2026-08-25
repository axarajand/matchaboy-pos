import 'package:intl/intl.dart';

/// Util format tampilan: Rupiah & tanggal lokal Indonesia.
///
/// Rupiah diformat manual (pemisah ribuan titik) agar hasilnya pasti
/// "Rp 20.000" tanpa bergantung pada data locale angka. Tanggal memakai
/// `intl` dengan locale `id` (pastikan `initializeDateFormatting('id')`
/// dipanggil sekali di `main`).

/// Format bilangan Rupiah, mis. `20000` → `"Rp 20.000"`.
String formatRupiah(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return 'Rp ${negative ? '-' : ''}$buffer';
}

final DateFormat _dateTimeFormat = DateFormat('d MMM yyyy • HH:mm', 'id');
final DateFormat _dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id');
final DateFormat _timeFormat = DateFormat('HH:mm', 'id');

/// mis. `"5 Jul 2026 • 14:30"`.
String formatDateTime(DateTime dt) => _dateTimeFormat.format(dt);

/// mis. `"Sabtu, 5 Juli 2026"`.
String formatDateLong(DateTime dt) => _dateFormat.format(dt);

/// mis. `"14:30"`.
String formatTime(DateTime dt) => _timeFormat.format(dt);
