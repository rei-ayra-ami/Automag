import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Хеширование паролей для безопасного хранения в БД.
///
/// Пароль никогда не хранится в открытом виде. Для каждого пользователя
/// генерируется случайная «соль», и в БД пишется строка `соль:хеш`, где
/// хеш = SHA-256(соль + пароль). При входе пароль хешируется так же и
/// сравнивается с сохранённым значением.
class PasswordHasher {
  static final Random _random = Random.secure();

  /// Создаёт хеш для нового пароля. Результат — строка вида `salt:hash`.
  static String hash(String password) {
    final salt = _generateSalt();
    final digest = _digest(salt, password);
    return '$salt:$digest';
  }

  /// Проверяет, что [password] соответствует ранее сохранённому [stored].
  static bool verify(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final expected = parts[1];
    return _digest(salt, password) == expected;
  }

  static String _generateSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _digest(String salt, String password) {
    return sha256.convert(utf8.encode('$salt$password')).toString();
  }
}
