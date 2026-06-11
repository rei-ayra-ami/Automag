import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../services/password.dart';
import 'database.dart';

/// Первичное наполнение базы данных при первом запуске приложения.
///
/// Если таблица товаров пуста — загружает каталог из `assets/data/parts.json`
/// и создаёт демонстрационный аккаунт администратора. Повторные запуски
/// ничего не делают (данные уже на месте).
class DatabaseSeeder {
  static const String adminEmail = 'admin@automag.kz';
  static const String adminPassword = 'admin123';

  static const String _assetPath = 'assets/data/parts.json';

  /// Стартовый остаток на складе для всех товаров (для демонстрации).
  static const int _defaultStock = 50;

  static Future<void> ensureSeeded(AppDatabase db) async {
    await _seedAdmin(db);
    await _seedProducts(db);
  }

  static Future<void> _seedAdmin(AppDatabase db) async {
    final existing = await db.findUserByEmail(adminEmail);
    if (existing != null) return;

    await db.createUser(
      email: adminEmail,
      passwordHash: PasswordHasher.hash(adminPassword),
      name: 'Администратор',
      role: 'admin',
    );
  }

  static Future<void> _seedProducts(AppDatabase db) async {
    final count = await db.productsCount();
    if (count > 0) return;

    final raw = await rootBundle.loadString(_assetPath);
    final data = json.decode(raw) as Map<String, dynamic>;
    final parts = data['parts'] as List<dynamic>;

    final rows = parts.map((e) {
      final p = e as Map<String, dynamic>;
      final specs = (p['specs'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toString()));
      return ProductsCompanion.insert(
        id: p['id'] as String,
        name: p['name'] as String,
        brand: Value(p['brand'] as String? ?? ''),
        model: Value(p['model'] as String? ?? 'Универсальный'),
        category: Value(p['category'] as String? ?? 'Прочее'),
        price: (p['price'] as num).round(),
        description: Value(p['description'] as String? ?? ''),
        image: Value(p['image'] as String?),
        specs: Value(json.encode(specs)),
        stock: const Value(_defaultStock),
      );
    }).toList();

    await db.insertProducts(rows);
  }
}
