import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'order_status.dart';

part 'database.g.dart';

// =====================================================================
//  Таблицы базы данных Automag
//
//  Схема — как в обычном интернет-магазине:
//    users        — пользователи (покупатели и админ), пароли в виде хеша
//    products     — товары (автозапчасти), наполняются из parts.json
//    orders       — заказы: кто оформил, способ получения, статус, сумма
//    order_items  — позиции заказа (снимок названия и цены на момент покупки)
//    order_status_history — история смены статусов заказа
// =====================================================================

@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get name => text().nullable()();
  TextColumn get phone => text().nullable()();
  // 'customer' — покупатель, 'admin' — администратор магазина.
  TextColumn get role => text().withDefault(const Constant('customer'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Product')
class Products extends Table {
  // Строковый id ('p1', 'p2', ...) — совместим с исходным каталогом.
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get brand => text().withDefault(const Constant(''))();
  TextColumn get model => text().withDefault(const Constant('Универсальный'))();
  TextColumn get category => text().withDefault(const Constant('Прочее'))();
  IntColumn get price => integer()();
  TextColumn get description => text().withDefault(const Constant(''))();
  // Путь к ассету (для заводского каталога) ИЛИ null, если фото загружено.
  TextColumn get image => text().nullable()();
  // Фото товара, загруженное вручную в админке (хранится прямо в БД).
  BlobColumn get imageBytes => blob().nullable()();
  // Характеристики хранятся JSON-строкой {"ключ": "значение"}.
  TextColumn get specs => text().withDefault(const Constant('{}'))();
  // Остаток на складе (для демонстрации «регистрации товара»).
  IntColumn get stock => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Order')
class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get customerName => text()();
  TextColumn get phone => text()();
  // 'delivery' — доставка, 'pickup' — самовывоз.
  TextColumn get deliveryMethod => text()();
  TextColumn get address => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('new'))();
  IntColumn get total => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('OrderItem')
class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id)();
  TextColumn get productId => text()();
  // Название и цена «замораживаются» на момент заказа — даже если потом
  // товар переименуют или подорожает, в заказе останется как было.
  TextColumn get name => text()();
  IntColumn get price => integer()();
  IntColumn get quantity => integer()();
}

@DataClassName('StatusChange')
class OrderStatusHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id)();
  TextColumn get status => text()();
  DateTimeColumn get changedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Одна позиция заказа для передачи в [AppDatabase.createOrder].
typedef NewOrderItem = ({String productId, String name, int price, int quantity});

@DriftDatabase(
  tables: [Users, Products, Orders, OrderItems, OrderStatusHistory],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._(super.executor);

  /// Единый экземпляр БД на всё приложение. На desktop/mobile это файл
  /// `automag` в каталоге приложения, в web — хранилище IndexedDB.
  ///
  /// Для web обязательно указываются пути к файлам SQLite (`sqlite3.wasm`)
  /// и фоновому воркеру (`drift_worker.js`) — они лежат в каталоге `web/`.
  static final AppDatabase instance = AppDatabase._(
    driftDatabase(
      name: 'automag',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );

  /// Конструктор для модульных тестов (база в памяти).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2: добавили колонку с фото товара, загружаемым в админке.
          if (from < 2) {
            await m.addColumn(products, products.imageBytes);
          }
        },
      );

  // --- Пользователи ----------------------------------------------------

  Future<User?> findUserByEmail(String email) {
    return (select(users)..where((u) => u.email.equals(email)))
        .getSingleOrNull();
  }

  Future<User?> findUserById(int id) {
    return (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();
  }

  Future<int> createUser({
    required String email,
    required String passwordHash,
    String? name,
    String? phone,
    String role = 'customer',
  }) {
    return into(users).insert(UsersCompanion.insert(
      email: email,
      passwordHash: passwordHash,
      name: Value(name),
      phone: Value(phone),
      role: Value(role),
    ));
  }

  // --- Товары ----------------------------------------------------------

  Future<int> productsCount() async {
    final count = countAll();
    final query = selectOnly(products)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<Product>> allProducts() {
    return (select(products)
          ..orderBy([(p) => OrderingTerm(expression: p.category), (p) => OrderingTerm(expression: p.name)]))
        .get();
  }

  Future<void> upsertProduct(ProductsCompanion product) {
    return into(products).insertOnConflictUpdate(product);
  }

  /// Массовая вставка товаров (используется при первичном наполнении).
  Future<void> insertProducts(List<ProductsCompanion> rows) {
    return batch((b) => b.insertAll(products, rows, mode: InsertMode.insertOrReplace));
  }

  // --- Заказы ----------------------------------------------------------

  /// Создаёт заказ вместе с позициями и первой записью истории статусов —
  /// всё в одной транзакции. Возвращает id нового заказа.
  Future<int> createOrder({
    required int userId,
    required String customerName,
    required String phone,
    required String deliveryMethod,
    String? address,
    required int total,
    required List<NewOrderItem> items,
  }) {
    return transaction(() async {
      final orderId = await into(orders).insert(OrdersCompanion.insert(
        userId: userId,
        customerName: customerName,
        phone: phone,
        deliveryMethod: deliveryMethod,
        address: Value(address),
        total: total,
      ));

      for (final item in items) {
        await into(orderItems).insert(OrderItemsCompanion.insert(
          orderId: orderId,
          productId: item.productId,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
        ));
      }

      await into(orderStatusHistory).insert(OrderStatusHistoryCompanion.insert(
        orderId: orderId,
        status: OrderStatus.newOrder.code,
      ));

      return orderId;
    });
  }

  /// Заказы конкретного покупателя, новые сверху.
  Future<List<Order>> ordersForUser(int userId) {
    return (select(orders)
          ..where((o) => o.userId.equals(userId))
          ..orderBy([(o) => OrderingTerm.desc(o.createdAt)]))
        .get();
  }

  /// Все заказы магазина (для админа), новые сверху.
  Future<List<Order>> allOrders() {
    return (select(orders)
          ..orderBy([(o) => OrderingTerm.desc(o.createdAt)]))
        .get();
  }

  Future<Order?> orderById(int id) {
    return (select(orders)..where((o) => o.id.equals(id))).getSingleOrNull();
  }

  Future<List<OrderItem>> itemsForOrder(int orderId) {
    return (select(orderItems)..where((i) => i.orderId.equals(orderId))).get();
  }

  Future<List<StatusChange>> historyForOrder(int orderId) {
    return (select(orderStatusHistory)
          ..where((h) => h.orderId.equals(orderId))
          ..orderBy([(h) => OrderingTerm(expression: h.changedAt)]))
        .get();
  }

  /// Меняет статус заказа и добавляет запись в историю — в одной транзакции.
  Future<void> updateOrderStatus(int orderId, String status) {
    return transaction(() async {
      await (update(orders)..where((o) => o.id.equals(orderId)))
          .write(OrdersCompanion(status: Value(status)));
      await into(orderStatusHistory).insert(
        OrderStatusHistoryCompanion.insert(orderId: orderId, status: status),
      );
    });
  }
}
