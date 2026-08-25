import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/database_service.dart';
import '../utils/formatters.dart';
import 'transaction_detail_screen.dart';

/// Riwayat Transaksi — daftar transaksi (terbaru di atas) + filter tanggal.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Transaction>> _future;
  DateTime? _filterDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    DateTime? from;
    DateTime? to;
    if (_filterDate != null) {
      from = DateTime(_filterDate!.year, _filterDate!.month, _filterDate!.day);
      to = from.add(const Duration(days: 1));
    }
    _future = DatabaseService.instance.getTransactions(from: from, to: to);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? now,
      firstDate: DateTime(2024),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _filterDate = picked;
        _load();
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _filterDate = null;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: Column(
        children: [
          _filterBar(),
          Expanded(
            child: FutureBuilder<List<Transaction>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final transactions = snapshot.data ?? const [];
                if (transactions.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada transaksi.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) =>
                      _tile(transactions[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(
                _filterDate == null
                    ? 'Semua tanggal'
                    : formatDateLong(_filterDate!),
              ),
            ),
          ),
          if (_filterDate != null)
            IconButton(
              onPressed: _clearFilter,
              icon: Icon(Icons.clear, color: scheme.error),
              tooltip: 'Hapus filter',
            ),
        ],
      ),
    );
  }

  Widget _tile(Transaction transaction) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(Icons.receipt_long, color: scheme.onPrimaryContainer),
        ),
        title: Text(
          transaction.transactionCode,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${formatDateTime(transaction.transactionDate)}\n'
          '${transaction.totalItems} item',
        ),
        isThreeLine: true,
        trailing: Text(
          formatRupiah(transaction.totalAmount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(
                transactionId: transaction.transactionId!,
              ),
            ),
          );
        },
      ),
    );
  }
}
