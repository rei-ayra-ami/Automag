import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.items.isEmpty) {
      return const Center(child: Text('Корзина пуста'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              final item = cart.items[index];

              return ListTile(
                title: Text(item.part.name),
                subtitle: Text('${item.part.model} • ${item.part.price} ₸'),
                leading: IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => cart.decrease(item.part),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('x${item.quantity}'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => cart.add(item.part),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Итого: ${cart.totalPrice} ₸',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Заказ оформлен'),
                        content: const Text(
                          'Ваш заказ принят. С вами свяжется менеджер.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Оформить заказ'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
