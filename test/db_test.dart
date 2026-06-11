import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';

import 'package:flutter_application_1/db/database.dart';
import 'package:flutter_application_1/db/order_status.dart';

/// Проверяет ключевую логику базы данных на базе в памяти:
/// регистрация пользователя и товара, оформление заказа, смену статусов.
void main() {
  // В тестовой среде (Dart VM) нет flutter-обёртки sqlite3, поэтому
  // на Linux подключаем системную библиотеку напрямую. В самом
  // приложении эту роль выполняет пакет sqlite3_flutter_libs.
  if (Platform.isLinux) {
    open.overrideForAll(() => DynamicLibrary.open('libsqlite3.so.0'));
  }

  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('пользователь, товар, заказ и история статусов', () async {
    // Пользователь
    final userId = await db.createUser(
      email: 'test@automag.kz',
      passwordHash: 'hash',
      name: 'Тестовый покупатель',
    );
    expect(userId, greaterThan(0));

    // Товар
    await db.upsertProduct(ProductsCompanion.insert(
      id: 'p1',
      name: 'Тормозные колодки',
      price: 18900,
    ));
    expect(await db.productsCount(), 1);

    // Заказ из одной позиции (2 шт.)
    final orderId = await db.createOrder(
      userId: userId,
      customerName: 'Тестовый покупатель',
      phone: '+77000000000',
      deliveryMethod: 'delivery',
      address: 'Алматы, ул. Абая 1',
      total: 37800,
      items: const [
        (
          productId: 'p1',
          name: 'Тормозные колодки',
          price: 18900,
          quantity: 2
        ),
      ],
    );

    final myOrders = await db.ordersForUser(userId);
    expect(myOrders, hasLength(1));
    expect(myOrders.first.total, 37800);
    expect(myOrders.first.status, OrderStatus.newOrder.code);

    final items = await db.itemsForOrder(orderId);
    expect(items, hasLength(1));
    expect(items.first.quantity, 2);

    // Изначально в истории один статус — «Новый»
    expect(await db.historyForOrder(orderId), hasLength(1));

    // Смена статуса добавляет запись в историю
    await db.updateOrderStatus(orderId, OrderStatus.shipped.code);
    final updated = await db.orderById(orderId);
    expect(updated!.status, OrderStatus.shipped.code);
    expect(await db.historyForOrder(orderId), hasLength(2));
  });

  test('email пользователя уникален', () async {
    await db.createUser(email: 'dup@automag.kz', passwordHash: 'h');
    expect(
      () => db.createUser(email: 'dup@automag.kz', passwordHash: 'h2'),
      throwsA(isA<Exception>()),
    );
  });
}
