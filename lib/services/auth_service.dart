import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import 'password.dart';

/// Результат входа или регистрации: либо пользователь, либо текст ошибки.
class AuthResult {
  final bool ok;
  final String? error;
  final User? user;

  const AuthResult._(this.ok, this.error, this.user);

  factory AuthResult.success(User user) => AuthResult._(true, null, user);
  factory AuthResult.failure(String error) =>
      AuthResult._(false, error, null);
}

/// Аутентификация поверх базы данных.
///
/// Учётные записи хранятся в таблице `users` (пароли — в виде хеша, см.
/// [PasswordHasher]). Факт того, кто сейчас вошёл, запоминается в
/// SharedPreferences как id пользователя — это «сессия».
class AuthService {
  static const _userIdKey = 'currentUserId';

  static AppDatabase get _db => AppDatabase.instance;

  /// Регистрация нового покупателя. Email должен быть уникальным.
  static Future<AuthResult> register(
    String email,
    String password, {
    String? name,
    String? phone,
  }) async {
    final normalized = email.trim().toLowerCase();
    final existing = await _db.findUserByEmail(normalized);
    if (existing != null) {
      return AuthResult.failure(
          'Пользователь с таким email уже зарегистрирован');
    }

    final id = await _db.createUser(
      email: normalized,
      passwordHash: PasswordHasher.hash(password),
      name: name,
      phone: phone,
    );
    await _saveSession(id);
    final user = await _db.findUserById(id);
    return AuthResult.success(user!);
  }

  /// Вход по email и паролю.
  static Future<AuthResult> login(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    final user = await _db.findUserByEmail(normalized);
    if (user == null || !PasswordHasher.verify(password, user.passwordHash)) {
      return AuthResult.failure('Неверный email или пароль');
    }
    await _saveSession(user.id);
    return AuthResult.success(user);
  }

  /// Текущий вошедший пользователь (или null, если никто не вошёл).
  static Future<User?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_userIdKey);
    if (id == null) return null;
    return _db.findUserById(id);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey) != null;
  }

  /// Является ли текущий пользователь администратором магазина.
  static Future<bool> isAdmin() async {
    final user = await currentUser();
    return user?.role == 'admin';
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  static Future<void> _saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }
}
