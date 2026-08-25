/// Produk matcha yang dijual kedai. Memetakan tabel `products`.
///
/// `productCode` HARUS sama persis dengan label kelas model YOLO (huruf kecil)
/// agar hasil deteksi bisa dihubungkan ke harga.
class Product {
  final int? productId;
  final String productName;
  final String productCode;

  /// Harga dalam Rupiah (bilangan bulat, tanpa desimal).
  final int price;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    this.productId,
    required this.productName,
    required this.productCode,
    required this.price,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      productId: map['product_id'] as int?,
      productName: map['product_name'] as String,
      productCode: map['product_code'] as String,
      price: (map['price'] as num).toInt(),
      description: map['description'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  /// Kolom yang boleh ditulis (tanpa id & timestamp — dikelola DatabaseService).
  Map<String, Object?> toDbMap() {
    return {
      'product_name': productName,
      'product_code': productCode,
      'price': price,
      'description': description,
      'is_active': isActive ? 1 : 0,
    };
  }

  Product copyWith({
    int? productId,
    String? productName,
    String? productCode,
    int? price,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      price: price ?? this.price,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDate(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }
}
