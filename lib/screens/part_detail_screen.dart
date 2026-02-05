import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/part.dart';
import '../providers/cart_provider.dart';

class PartDetailScreen extends StatelessWidget {
  final Part part;

  const PartDetailScreen({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(part.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                part.image,
                height: 150,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              part.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Подходит для: ${part.model}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              '${part.price} ₸',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Добавить в корзину'),
                onPressed: () {
                  context.read<CartProvider>().add(part);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Добавлено в корзину')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
