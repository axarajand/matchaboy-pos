import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/database_service.dart';
import '../utils/formatters.dart';
import 'product_form_screen.dart';

/// Manajemen Produk — daftar produk (card) + edit tiap card + FAB tambah.
class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = DatabaseService.instance.getAllProducts();
  }

  void _reload() {
    setState(() {
      _future = DatabaseService.instance.getAllProducts();
    });
  }

  Future<void> _openForm([Product? product]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (saved == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Produk')),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data ?? const [];
          if (products.isEmpty) {
            return const Center(child: Text('Belum ada produk.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, index) => _card(products[index]),
          );
        },
      ),
    );
  }

  Widget _card(Product product) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.productCode,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(product.price),
                    style: TextStyle(color: scheme.primary, fontSize: 15),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _openForm(product),
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
          ],
        ),
      ),
    );
  }
}
