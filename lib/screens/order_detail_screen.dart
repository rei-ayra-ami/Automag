import 'package:flutter/material.dart';

import '../db/database.dart';
import '../db/order_status.dart';
import '../services/order_service.dart';
import '../widgets/status_badge.dart';
import 'catalog_screen.dart' show formatPrice;

/// Детали одного заказа: состав, контакты, история статусов.
/// В режиме [admin] добавляется блок смены статуса.
class OrderDetailScreen extends StatefulWidget {
  final Order order;
  final bool admin;

  const OrderDetailScreen({
    super.key,
    required this.order,
    this.admin = false,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order _order;
  late Future<List<OrderItem>> _itemsFuture;
  late Future<List<StatusChange>> _historyFuture;
  bool _changing = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _itemsFuture = OrderService.itemsOf(_order.id);
    _reloadHistory();
  }

  void _reloadHistory() {
    _historyFuture = OrderService.historyOf(_order.id);
  }

  Future<void> _changeStatus(OrderStatus status) async {
    if (_changing || status.code == _order.status) return;
    setState(() => _changing = true);
    await OrderService.updateStatus(_order.id, status);
    if (!mounted) return;
    setState(() {
      _order = _order.copyWith(status: status.code);
      _changing = false;
      _reloadHistory();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Статус изменён: ${status.label}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = OrderStatus.fromCode(_order.status);
    final isPickup = _order.deliveryMethod == 'pickup';

    return Scaffold(
      appBar: AppBar(title: Text('Заказ №${_order.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Заказ №${_order.id}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 4),
          Text('Оформлен: ${formatDateTime(_order.createdAt)}',
              style: TextStyle(color: Colors.grey.shade600)),
          const Divider(height: 28),

          // --- Получатель ---
          const Text('Получатель',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _infoRow(Icons.person_outline, _order.customerName),
          _infoRow(Icons.phone_outlined, _order.phone),
          _infoRow(
            isPickup ? Icons.storefront_outlined : Icons.local_shipping_outlined,
            isPickup ? 'Самовывоз' : 'Доставка',
          ),
          if (!isPickup && (_order.address?.isNotEmpty ?? false))
            _infoRow(Icons.home_outlined, _order.address!),
          const Divider(height: 28),

          // --- Состав заказа ---
          const Text('Состав заказа',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<List<OrderItem>>(
            future: _itemsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final items = snapshot.data!;
              return Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.name}  ×${item.quantity}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            '${formatPrice(item.price * item.quantity)} ₸',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Итого',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${formatPrice(_order.total)} ₸',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),

          // --- Управление статусом (только админ) ---
          if (widget.admin) ...[
            const Divider(height: 32),
            const Text('Изменить статус',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in [...OrderStatus.flow, OrderStatus.cancelled])
                  ChoiceChip(
                    label: Text(s.label),
                    avatar: Icon(s.icon, size: 16, color: s.color),
                    selected: s.code == _order.status,
                    onSelected:
                        _changing ? null : (_) => _changeStatus(s),
                  ),
              ],
            ),
          ],

          // --- История статусов ---
          const Divider(height: 32),
          const Text('История статусов',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<List<StatusChange>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final history = snapshot.data!;
              return Column(
                children: [
                  for (final change in history)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        OrderStatus.fromCode(change.status).icon,
                        color: OrderStatus.fromCode(change.status).color,
                      ),
                      title:
                          Text(OrderStatus.fromCode(change.status).label),
                      subtitle: Text(formatDateTime(change.changedAt)),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
