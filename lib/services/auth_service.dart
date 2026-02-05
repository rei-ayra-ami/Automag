import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _loginKey = 'login';
  static const _passwordKey = 'password';
  static const _isLoggedKey = 'isLogged';

  static Future<void> register(String login, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginKey, login);
    await prefs.setString(_passwordKey, password);
  }

  static Future<bool> login(String login, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedLogin = prefs.getString(_loginKey);
    final savedPass = prefs.getString(_passwordKey);

    if (login == savedLogin && password == savedPass) {
      await prefs.setBool(_isLoggedKey, true);
      return true;
    }
    return false;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedKey) ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedKey, false);
  }
}
