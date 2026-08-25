import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/transaction_item.dart';
import '../services/database_service.dart';
import '../utils/formatters.dart';
import 'transaction_success_screen.dart';

/// Konfirmasi Transaksi — verifikasi akhir. User bisa menyesuaikan manual
/// (tambah/kurang/hapus item) bila deteksi keliru, lalu simpan.
class ConfirmTransactionScreen extends StatefulWidget {
  final List<TransactionItem> items;

  const ConfirmTransactionScreen({super.key, required this.items});

  @override
  State<ConfirmTransactionScreen> createState() =>
      _ConfirmTransactionScreenState();
}

class _ConfirmTransactionScreenState extends State<ConfirmTransactionScreen> {
  late List<TransactionItem> _items;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = List<TransactionItem>.from(widget.items);
  }

  int get _totalItems => _items.fold(0, (sum, i) => sum + i.quantity);
  int get _totalAmount => _items.fold(0, (sum, i) => sum + i.subtotal);

  void _increment(int index) {
    setState(() {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
      );
    });
  }

  void _decrement(int index) {
    setState(() {
      final current = _items[index];
      if (current.quantity > 1) {
        _items[index] = current.copyWith(quantity: current.quantity - 1);
      } else {
        _items.removeAt(index);
      }
    });
  }

  void _remove(int index) => setState(() => _items.removeAt(index));

  Future<void> _addItem() async {
    final products = await DatabaseService.instance.getActiveProducts();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Tambah item',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          for (final product in products)
            ListTile(
              title: Text(product.productName),
              trailing: Text(formatRupiah(product.price)),
              onTap: () {
                _addProduct(product);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  void _addProduct(Product product) {
    setState(() {
      final index = _items.indexWhere((i) => i.productId == product.productId);
      if (index >= 0) {
        _items[index] = _items[index].copyWith(
          quantity: _items[index].quantity + 1,
        );
      } else {
        _items.add(TransactionItem.forProduct(product, quantity: 1));
      }
    });
  }

  Future<void> _confirm() async {
    if (_items.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final transaction = await DatabaseService.instance.saveTransaction(
        items: _items,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TransactionSuccessScreen(transaction: transaction),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Transaksi'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Tambah item'),
          ),
        ],
      ),
      body: Column(
        children: [
          _timeInfo(),
          Expanded(child: _itemList()),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _timeInfo() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: scheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(Icons.schedule, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            formatDateTime(DateTime.now()),
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _itemList() {
    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Belum ada item.\nTambahkan item untuk melanjutkan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName ?? item.productCode ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatRupiah(item.unitPrice)} • '
                        'subtotal ${formatRupiah(item.subtotal)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _decrement(index),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _increment(index),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                IconButton(
                  onPressed: () => _remove(index),
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bottomBar() {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_totalItems item'),
                  Text(
                    formatRupiah(_totalAmount),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Batalkan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: (_items.isEmpty || _saving) ? null : _confirm,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
