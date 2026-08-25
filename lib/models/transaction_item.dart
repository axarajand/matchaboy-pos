import 'product.dart';

/// Satu baris item dalam transaksi (satu varian). Memetakan tabel
/// `transaction_items`.
///
/// `unitPrice` disimpan per item agar transaksi lama tetap konsisten meski
/// harga produk berubah kemudian. `confidenceScore` menyimpan keyakinan
/// deteksi untuk audit. `productName`/`productCode` hanya terisi bila baris
/// berasal dari query yang menggabungkan tabel `products`.
class TransactionItem {
  final int? itemId;
  final int? transactionId;
  final int productId;
  final int quantity;

  /// Harga satuan (Rupiah) saat transaksi terjadi.
  final int unitPrice;

  /// `quantity * unitPrice`.
  final int subtotal;
  final double? confidenceScore;

  // Field hasil join (opsional).
  final String? productName;
  final String? productCode;

  const TransactionItem({
    this.itemId,
    this.transactionId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.confidenceScore,
    this.productName,
    this.productCode,
  });

  /// Bentuk item dari sebuah [product] + jumlah cup, hitung subtotal otomatis.
  /// Dipakai di layar Hasil Deteksi / Konfirmasi.
  factory TransactionItem.forProduct(
    Product product, {
    required int quantity,
    double? confidenceScore,
  }) {
    return TransactionItem(
      productId: product.productId!,
      quantity: quantity,
      unitPrice: product.price,
      subtotal: product.price * quantity,
      confidenceScore: confidenceScore,
      productName: product.productName,
      productCode: product.productCode,
    );
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      itemId: map['item_id'] as int?,
      transactionId: map['transaction_id'] as int?,
      productId: (map['product_id'] as num).toInt(),
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: (map['unit_price'] as num).toInt(),
      subtotal: (map['subtotal'] as num).toInt(),
      confidenceScore: (map['confidence_score'] as num?)?.toDouble(),
      productName: map['product_name'] as String?,
      productCode: map['product_code'] as String?,
    );
  }

  /// Kolom yang boleh ditulis (tanpa id & transaction_id — dikelola
  /// DatabaseService saat menyimpan transaksi).
  Map<String, Object?> toDbMap() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'confidence_score': confidenceScore,
    };
  }

  TransactionItem copyWith({int? quantity}) {
    final q = quantity ?? this.quantity;
    return TransactionItem(
      itemId: itemId,
      transactionId: transactionId,
      productId: productId,
      quantity: q,
      unitPrice: unitPrice,
      subtotal: unitPrice * q,
      confidenceScore: confidenceScore,
      productName: productName,
      productCode: productCode,
    );
  }
}
