import 'package:path/path.dart' as p;
// `Transaction` disembunyikan agar tidak bentrok dengan model kita.
import 'package:sqflite/sqflite.dart' hide Transaction;

import '../models/product.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';

/// Layanan basis data SQLite lokal untuk Matchaboy POS.
///
/// Bertanggung jawab atas: inisialisasi & pembukaan DB, pembuatan skema 3 tabel
/// berelasi (`products` 1—* `transaction_items` *—1 `transactions`), *seed*
/// produk awal, serta CRUD & query yang dipakai alur kasir.
///
/// Semua berjalan **offline** (NFR-05); DB tersimpan di penyimpanan privat
/// aplikasi (NFR-08). Kolom bertipe DATETIME disimpan sebagai string ISO8601.
///
/// Gunakan sebagai singleton: `DatabaseService.instance`.
class DatabaseService {
  DatabaseService._internal();

  /// Instance tunggal yang dipakai ulang di seluruh aplikasi.
  static final DatabaseService instance = DatabaseService._internal();

  static const String _dbName = 'matchaboy_pos.db';
  static const int _dbVersion = 1;

  // Nama tabel (dipakai konsisten di seluruh query).
  static const String tableProducts = 'products';
  static const String tableTransactions = 'transactions';
  static const String tableTransactionItems = 'transaction_items';

  Database? _db;

  /// Basis data yang sudah terbuka; dibuka sekali lalu dipakai ulang.
  Future<Database> get database async {
    return _db ??= await _open();
  }

  /// Menutup koneksi DB (mis. saat testing). Aman dipanggil ulang.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<Database> _open() async {
    final basePath = await getDatabasesPath();
    final path = p.join(basePath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  /// Aktifkan penegakan foreign key (SQLite mematikannya secara default).
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Buat ketiga tabel lalu isi produk awal.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableProducts (
        product_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        product_name  TEXT    NOT NULL UNIQUE,
        product_code  TEXT    NOT NULL UNIQUE,
        price         INTEGER NOT NULL,
        description   TEXT,
        is_active     INTEGER NOT NULL DEFAULT 1,
        created_at    TEXT    NOT NULL,
        updated_at    TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableTransactions (
        transaction_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_code  TEXT    NOT NULL UNIQUE,
        transaction_date  TEXT    NOT NULL,
        total_items       INTEGER NOT NULL,
        total_amount      INTEGER NOT NULL,
        payment_status    TEXT    NOT NULL DEFAULT 'completed',
        notes             TEXT,
        created_at        TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableTransactionItems (
        item_id           INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id    INTEGER NOT NULL,
        product_id        INTEGER NOT NULL,
        quantity          INTEGER NOT NULL,
        unit_price        INTEGER NOT NULL,
        subtotal          INTEGER NOT NULL,
        confidence_score  REAL,
        FOREIGN KEY (transaction_id) REFERENCES $tableTransactions (transaction_id)
          ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES $tableProducts (product_id)
          ON DELETE RESTRICT
      )
    ''');

    // Indeks bantu untuk query detail transaksi.
    await db.execute(
      'CREATE INDEX idx_items_transaction ON $tableTransactionItems (transaction_id)',
    );

    await _seedProducts(db);
  }

  // ----------------------------------------------------------------------------
  // SEED PRODUK
  // ----------------------------------------------------------------------------

  /// Produk awal. `product_code` HARUS sama persis dengan label kelas model
  /// YOLO (huruf kecil) agar hasil deteksi bisa dipetakan ke harga.
  /// Harga di bawah PLACEHOLDER — ganti dengan harga asli kedai.
  static const List<Map<String, Object>> _seedProductsData = [
    {'product_name': 'Original', 'product_code': 'og', 'price': 18000},
    {'product_name': 'Vanilla', 'product_code': 'vanilla', 'price': 20000},
    {'product_name': 'Choco', 'product_code': 'choko', 'price': 20000},
    {'product_name': 'Taro', 'product_code': 'taro', 'price': 20000},
    {'product_name': 'Pistachio', 'product_code': 'pistachio', 'price': 22000},
    {'product_name': 'Red Velvet', 'product_code': 'red_velvet', 'price': 22000},
  ];

  Future<void> _seedProducts(DatabaseExecutor db) async {
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (final product in _seedProductsData) {
      batch.insert(tableProducts, {
        ...product,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  // ----------------------------------------------------------------------------
  // PRODUCTS — CRUD & lookup (FR-05, FR-10)
  // ----------------------------------------------------------------------------

  /// Semua produk, terurut berdasarkan nama.
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final rows = await db.query(tableProducts, orderBy: 'product_name ASC');
    return rows.map(Product.fromMap).toList();
  }

  /// Hanya produk aktif (dipakai saat kalkulasi transaksi baru).
  Future<List<Product>> getActiveProducts() async {
    final db = await database;
    final rows = await db.query(
      tableProducts,
      where: 'is_active = 1',
      orderBy: 'product_name ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  /// Cari produk lewat `product_code` (= label kelas model). Kunci pemetaan
  /// hasil deteksi → harga. Mengembalikan `null` jika tidak ada.
  Future<Product?> getProductByCode(String productCode) async {
    final db = await database;
    final rows = await db.query(
      tableProducts,
      where: 'product_code = ?',
      whereArgs: [productCode],
      limit: 1,
    );
    return rows.isEmpty ? null : Product.fromMap(rows.first);
  }

  Future<Product?> getProductById(int productId) async {
    final db = await database;
    final rows = await db.query(
      tableProducts,
      where: 'product_id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    return rows.isEmpty ? null : Product.fromMap(rows.first);
  }

  /// Tambah produk baru; `product_name`/`product_code` harus unik (melempar
  /// bila bentrok). Mengembalikan `product_id` baru.
  Future<int> insertProduct(Product product) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.insert(tableProducts, {
      ...product.toDbMap(),
      'created_at': now,
      'updated_at': now,
    });
  }

  /// Perbarui produk (butuh `productId`); `updated_at` selalu di-refresh.
  /// Mengembalikan jumlah baris terpengaruh.
  Future<int> updateProduct(Product product) async {
    assert(product.productId != null, 'updateProduct butuh productId');
    final db = await database;
    return db.update(
      tableProducts,
      {...product.toDbMap(), 'updated_at': DateTime.now().toIso8601String()},
      where: 'product_id = ?',
      whereArgs: [product.productId],
    );
  }

  /// Nonaktifkan/aktifkan produk (soft delete) agar transaksi lama tetap
  /// konsisten. Mengembalikan jumlah baris terpengaruh.
  Future<int> setProductActive(int productId, bool isActive) async {
    final db = await database;
    return db.update(
      tableProducts,
      {
        'is_active': isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  // ----------------------------------------------------------------------------
  // TRANSACTIONS — simpan & query (FR-08, FR-09)
  // ----------------------------------------------------------------------------

  /// Buat kode transaksi unik berformat `TRX-YYYYMMDD-NNN` untuk [date],
  /// dengan NNN = urutan harian (mulai 001). Dipanggil di dalam transaksi DB
  /// agar penghitungan urutan konsisten.
  Future<String> _generateTransactionCode(
    DatabaseExecutor txn,
    DateTime date,
  ) async {
    final datePart =
        '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
    final prefix = 'TRX-$datePart-';

    final result = await txn.rawQuery(
      'SELECT COUNT(*) AS c FROM $tableTransactions '
      'WHERE transaction_code LIKE ?',
      ['$prefix%'],
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    final sequence = (count + 1).toString().padLeft(3, '0');
    return '$prefix$sequence';
  }

  /// Simpan satu transaksi beserta item-nya secara atomik (FR-08).
  ///
  /// `total_items` & `total_amount` dihitung dari [items]. Kode transaksi
  /// dibuat otomatis. Mengembalikan [Transaction] lengkap (dengan id & kode).
  Future<Transaction> saveTransaction({
    required List<TransactionItem> items,
    String paymentStatus = 'completed',
    String? notes,
    DateTime? date,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Transaksi harus memiliki minimal satu item.');
    }

    final db = await database;
    final now = date ?? DateTime.now();
    final nowIso = now.toIso8601String();

    return db.transaction((txn) async {
      var totalItems = 0;
      var totalAmount = 0;
      for (final item in items) {
        totalItems += item.quantity;
        totalAmount += item.subtotal;
      }

      final code = await _generateTransactionCode(txn, now);

      final transactionId = await txn.insert(tableTransactions, {
        'transaction_code': code,
        'transaction_date': nowIso,
        'total_items': totalItems,
        'total_amount': totalAmount,
        'payment_status': paymentStatus,
        'notes': notes,
        'created_at': nowIso,
      });

      final batch = txn.batch();
      for (final item in items) {
        batch.insert(tableTransactionItems, {
          ...item.toDbMap(),
          'transaction_id': transactionId,
        });
      }
      await batch.commit(noResult: true);

      return Transaction(
        transactionId: transactionId,
        transactionCode: code,
        transactionDate: now,
        totalItems: totalItems,
        totalAmount: totalAmount,
        paymentStatus: paymentStatus,
        notes: notes,
        createdAt: now,
      );
    });
  }

  /// Riwayat transaksi (terbaru di atas), opsional difilter rentang tanggal.
  /// [from]/[to] inklusif berdasarkan `transaction_date`.
  Future<List<Transaction>> getTransactions({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object>[];
    if (from != null) {
      where.add('transaction_date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('transaction_date <= ?');
      args.add(to.toIso8601String());
    }
    final rows = await db.query(
      tableTransactions,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'transaction_date DESC, transaction_id DESC',
    );
    return rows.map(Transaction.fromMap).toList();
  }

  Future<Transaction?> getTransactionById(int transactionId) async {
    final db = await database;
    final rows = await db.query(
      tableTransactions,
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      limit: 1,
    );
    return rows.isEmpty ? null : Transaction.fromMap(rows.first);
  }

  /// Item satu transaksi, digabung nama & kode produk (untuk Detail Transaksi).
  Future<List<TransactionItem>> getTransactionItems(int transactionId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT ti.*, p.product_name, p.product_code
      FROM $tableTransactionItems ti
      JOIN $tableProducts p ON p.product_id = ti.product_id
      WHERE ti.transaction_id = ?
      ORDER BY ti.item_id ASC
      ''',
      [transactionId],
    );
    return rows.map(TransactionItem.fromMap).toList();
  }

  /// Ringkasan harian untuk Dashboard: jumlah transaksi & total pendapatan
  /// pada tanggal [date] (default hari ini).
  Future<Map<String, int>> getDailySummary({DateTime? date}) async {
    final db = await database;
    final day = date ?? DateTime.now();
    final datePrefix =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS transaction_count,
             COALESCE(SUM(total_amount), 0) AS revenue
      FROM $tableTransactions
      WHERE transaction_date LIKE ?
      ''',
      ['$datePrefix%'],
    );
    final row = result.first;
    return {
      'transaction_count': (row['transaction_count'] as int?) ?? 0,
      'revenue': (row['revenue'] as int?) ?? 0,
    };
  }
}
