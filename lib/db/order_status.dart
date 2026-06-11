import 'package:flutter/material.dart';

/// Статусы заказа — как в обычных интернет-магазинах.
///
/// В БД хранится «кодовое» значение ([code], например `new`), а
/// пользователю показывается русская подпись ([label]). Так данные
/// остаются стабильными, а интерфейс — понятным.
enum OrderStatus {
  newOrder('new', 'Новый', Icons.fiber_new, Colors.blue),
  processing('processing', 'В обработке', Icons.inventory_2, Colors.orange),
  shipped('shipped', 'Отправлен', Icons.local_shipping, Colors.purple),
  delivered('delivered', 'Доставлен', Icons.check_circle, Colors.green),
  cancelled('cancelled', 'Отменён', Icons.cancel, Colors.red);

  const OrderStatus(this.code, this.label, this.icon, this.color);

  final String code;
  final String label;
  final IconData icon;
  final Color color;

  /// Восстановить статус из строки в БД. Неизвестное значение → [newOrder].
  static OrderStatus fromCode(String code) {
    return OrderStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => OrderStatus.newOrder,
    );
  }

  /// Порядок «движения» заказа для админки (без отмены).
  static const List<OrderStatus> flow = [
    OrderStatus.newOrder,
    OrderStatus.processing,
    OrderStatus.shipped,
    OrderStatus.delivered,
  ];
}
