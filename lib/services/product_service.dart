import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;

import '../db/database.dart';
import '../models/part.dart';

/// Доступ к каталогу товаров из локальной базы данных.
///
/// Раньше каталог приходил по сети (FastAPI), теперь — из встроенной БД
/// (таблица `products`). Метод [fetchParts] сохранил прежнее имя и тип
/// возврата, чтобы экраны каталога менялись минимально.
class ProductService {
  static AppDatabase get _db => AppDatabase.instance;

  /// Все товары каталога в виде модели [Part].
  static Future<List<Part>> fetchParts() async {
    final rows = await _db.allProducts();
    return rows.map(_toPart).toList();
  }

  /// Добавить (зарегистрировать) новый товар в каталог. Используется
  /// в админ-панели. Если [id] не задан — генерируется автоматически.
  static Future<void> addProduct({
    String? id,
    required String name,
    required String brand,
    required String model,
    required String category,
    required int price,
    required String description,
    String? image,
    Uint8List? imageBytes,
    Map<String, String> specs = const {},
    int stock = 0,
  }) {
    final productId = id ?? 'NEW-${DateTime.now().millisecondsSinceEpoch}';
    return _db.upsertProduct(ProductsCompanion.insert(
      id: productId,
      name: name,
      brand: Value(brand),
      model: Value(model),
      category: Value(category),
      price: price,
      description: Value(description),
      image: Value(image),
      imageBytes: Value(imageBytes),
      specs: Value(json.encode(specs)),
      stock: Value(stock),
    ));
  }

  static Part _toPart(Product p) {
    final specs = (json.decode(p.specs) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v.toString()));
    return Part(
      id: p.id,
      name: p.name,
      brand: p.brand,
      model: p.model,
      category: p.category,
      price: p.price,
      description: p.description,
      specs: specs,
      image: p.image,
      imageBytes: p.imageBytes,
    );
  }
}
