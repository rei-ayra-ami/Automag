import 'package:flutter/material.dart';

import '../db/database.dart';
import '../db/order_status.dart';
import '../services/order_service.dart';
import '../widgets/status_badge.dart';
import 'catalog_screen.dart' show formatPrice;
import 'order_detail_screen.dart';

/// Админ-панель: все заказы магазина. Видно, кто оформил заказ, на какую
/// сумму и в каком он статусе. По тапу открывается заказ со сменой статуса.
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = OrderService.allOrders();
  }

  void _reload() {
    setState(() => _ordersFuture = OrderService.allOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление заказами'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Заказов пока нет'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final order = orders[index];
                final status = OrderStatus.fromCode(order.status);
                return Card(
                  elevation: 1,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('Заказ №${order.id} · ${order.customerName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: status),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${formatDateTime(order.createdAt)} · '
                        '${order.phone}\n'
                        'Сумма: ${formatPrice(order.total)} ₸',
                        style: TextStyle(
                            color: Colors.grey.shade700, height: 1.4),
                      ),
                    ),
                    isThreeLine: true,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderDetailScreen(order: order, admin: true),
                        ),
                      );
                      _reload(); // статус мог измениться
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
