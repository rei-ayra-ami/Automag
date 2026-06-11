import '../db/database.dart';
import '../db/order_status.dart';
import '../models/cart_item.dart';
import 'auth_service.dart';

/// Оформление и отслеживание заказов поверх базы данных.
class OrderService {
  static AppDatabase get _db => AppDatabase.instance;

  /// Оформляет заказ из корзины текущего пользователя.
  /// Возвращает номер созданного заказа или null, если никто не вошёл.
  static Future<int?> createOrder({
    required List<CartItem> items,
    required String customerName,
    required String phone,
    required String deliveryMethod,
    String? address,
  }) async {
    final user = await AuthService.currentUser();
    if (user == null || items.isEmpty) return null;

    final total =
        items.fold<int>(0, (sum, i) => sum + i.part.price * i.quantity);

    return _db.createOrder(
      userId: user.id,
      customerName: customerName,
      phone: phone,
      deliveryMethod: deliveryMethod,
      address: address,
      total: total,
      items: [
        for (final i in items)
          (
            productId: i.part.id,
            name: i.part.name,
            price: i.part.price,
            quantity: i.quantity,
          ),
      ],
    );
  }

  /// Заказы текущего покупателя (для экрана «Мои заказы»).
  static Future<List<Order>> myOrders() async {
    final user = await AuthService.currentUser();
    if (user == null) return [];
    return _db.ordersForUser(user.id);
  }

  /// Все заказы магазина (для админ-панели).
  static Future<List<Order>> allOrders() => _db.allOrders();

  static Future<List<OrderItem>> itemsOf(int orderId) =>
      _db.itemsForOrder(orderId);

  static Future<List<StatusChange>> historyOf(int orderId) =>
      _db.historyForOrder(orderId);

  /// Сменить статус заказа (для админ-панели).
  static Future<void> updateStatus(int orderId, OrderStatus status) =>
      _db.updateOrderStatus(orderId, status.code);
}
