import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/part.dart';

/// Слой интеграции с источником данных об автозапчастях.
///
/// Основной источник — REST API (FastAPI, см. backend/main.py):
///   GET http://127.0.0.1:8000/api/parts  →  JSON-массив запчастей.
/// Если сервер недоступен (не запущен, нет сети), приложение
/// автоматически откатывается на локальный каталог [_assetPath]
/// (assets/data/parts.json) — это гарантирует работу офлайн.
class ApiService {
  /// Базовый URL API. 127.0.0.1 работает для веб (Chrome) и desktop.
  /// Для эмулятора Android используйте http://10.0.2.2:8000.
  static const String _baseUrl = 'http://127.0.0.1:8000';
  static const String _partsUrl = '$_baseUrl/api/parts';

  static const String _assetPath = 'assets/data/parts.json';

  /// Таймаут запроса к API — чтобы при недоступном сервере
  /// не подвисать, а быстро уйти в фолбэк.
  static const Duration _timeout = Duration(seconds: 5);

  /// Загрузка списка автозапчастей: сначала API, при ошибке — ассет.
  static Future<List<Part>> fetchParts() async {
    try {
      return await _fetchFromApi();
    } catch (e) {
      debugPrint('ApiService: API недоступен ($e). Использую локальный каталог.');
      return _fetchFromAsset();
    }
  }

  /// Список доступных категорий (для фильтра в каталоге).
  static Future<List<String>> fetchCategories() async {
    final parts = await fetchParts();
    final categories = parts.map((p) => p.category).toSet().toList()..sort();
    return categories;
  }

  // --- Источники данных --------------------------------------------------

  /// Реальный REST API. Возвращает JSON-массив (не {"parts":[]}).
  /// utf8.decode(bodyBytes) обязателен, иначе кириллица ломается.
  static Future<List<Part>> _fetchFromApi() async {
    final response = await http.get(Uri.parse(_partsUrl)).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки данных (${response.statusCode})');
    }
    final decoded = json.decode(utf8.decode(response.bodyBytes));
    final List<dynamic> parts = decoded as List<dynamic>;
    return parts
        .map((e) => Part.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Локальный каталог из ассетов. Формат — объект {"parts": [...]}.
  static Future<List<Part>> _fetchFromAsset() async {
    final raw = await rootBundle.loadString(_assetPath);
    final data = json.decode(raw) as Map<String, dynamic>;
    final List<dynamic> parts = data['parts'] as List<dynamic>;
    return parts
        .map((e) => Part.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
