import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/part.dart';
import '../providers/cart_provider.dart';
import 'catalog_screen.dart' show PartImage, formatPrice;

class PartDetailScreen extends StatelessWidget {
  final Part part;

  const PartDetailScreen({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(part.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: PartImage(part: part, iconSize: 90),
          ),
          const SizedBox(height: 16),
          Chip(
            label: Text(part.category),
            avatar: Icon(part.categoryIcon, size: 18),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(height: 8),
          Text(
            part.name,
            style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Производитель: ${part.brand}',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 2),
          Text(
            'Подходит для: ${part.model}',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Text(
            '${formatPrice(part.price)} ₸',
            style:
                const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 32),
          const Text(
            'Описание',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(part.description, style: const TextStyle(fontSize: 15, height: 1.4)),
          if (part.specs.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Характеристики',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _SpecsTable(specs: part.specs),
          ],
          const SizedBox(height: 24),
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              final inCart = cart.quantityOf(part.id);
              return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(inCart > 0
                  ? 'В корзине: $inCart · добавить ещё'
                  : 'Добавить в корзину'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                final cart = context.read<CartProvider>();
                cart.add(part);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green.shade700,
                      duration: const Duration(seconds: 2),
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '«${part.name}» в корзине · ${cart.totalCount} шт.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
              },
            ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SpecsTable extends StatelessWidget {
  final Map<String, String> specs;
  const _SpecsTable({required this.specs});

  @override
  Widget build(BuildContext context) {
    final entries = specs.entries.toList();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++)
            Container(
              decoration: BoxDecoration(
                color: i.isEven ? Colors.grey.shade50 : Colors.white,
                border: i == entries.length - 1
                    ? null
                    : Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      entries[i].key,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      entries[i].value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
