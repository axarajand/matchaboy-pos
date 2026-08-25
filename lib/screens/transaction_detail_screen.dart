import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../services/database_service.dart';
import '../utils/formatters.dart';

/// Detail Transaksi — rincian satu transaksi: kode, tanggal-waktu, daftar
/// varian + jumlah + subtotal, total keseluruhan.
class TransactionDetailScreen extends StatefulWidget {
  final int transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late final Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailData> _load() async {
    final db = DatabaseService.instance;
    final transaction = await db.getTransactionById(widget.transactionId);
    final items = await db.getTransactionItems(widget.transactionId);
    return _DetailData(transaction, items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi')),
      body: FutureBuilder<_DetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null || data.transaction == null) {
            return const Center(child: Text('Transaksi tidak ditemukan.'));
          }
          return _content(data.transaction!, data.items);
        },
      ),
    );
  }

  Widget _content(Transaction transaction, List<TransactionItem> items) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.transactionCode,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatDateTime(transaction.transactionDate),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Rincian item',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...items.map((item) => _itemTile(item)),
        const SizedBox(height: 8),
        Card(
          color: scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (${transaction.totalItems} item)',
                  style: TextStyle(
                    fontSize: 16,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  formatRupiah(transaction.totalAmount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _itemTile(TransactionItem item) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(
            '${item.quantity}',
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          item.productName ?? item.productCode ?? '-',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${item.quantity} × ${formatRupiah(item.unitPrice)}'),
        trailing: Text(
          formatRupiah(item.subtotal),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _DetailData {
  final Transaction? transaction;
  final List<TransactionItem> items;
  _DetailData(this.transaction, this.items);
}
