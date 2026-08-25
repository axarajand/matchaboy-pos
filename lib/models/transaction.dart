/// Satu transaksi penjualan. Memetakan tabel `transactions`.
///
/// `transactionCode` berformat `TRX-YYYYMMDD-NNN` dan dibuat oleh
/// DatabaseService saat menyimpan. Rincian per varian ada di
/// `transaction_items` (lihat [TransactionItem]).
class Transaction {
  final int? transactionId;
  final String transactionCode;
  final DateTime transactionDate;

  /// Total jumlah cup di seluruh item.
  final int totalItems;

  /// Total nilai transaksi dalam Rupiah.
  final int totalAmount;
  final String paymentStatus;
  final String? notes;
  final DateTime? createdAt;

  const Transaction({
    this.transactionId,
    required this.transactionCode,
    required this.transactionDate,
    required this.totalItems,
    required this.totalAmount,
    this.paymentStatus = 'completed',
    this.notes,
    this.createdAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      transactionId: map['transaction_id'] as int?,
      transactionCode: map['transaction_code'] as String,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      totalItems: (map['total_items'] as num).toInt(),
      totalAmount: (map['total_amount'] as num).toInt(),
      paymentStatus: map['payment_status'] as String? ?? 'completed',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }
}
