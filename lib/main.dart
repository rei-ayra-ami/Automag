import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'db/database.dart';
import 'db/seed.dart';
import 'providers/cart_provider.dart';

void main() async {
  // Нужно до обращения к БД и ассетам (rootBundle).
  WidgetsFlutterBinding.ensureInitialized();

  // Создаём/наполняем базу данных при первом запуске:
  // каталог из parts.json + демонстрационный аккаунт администратора.
  await DatabaseSeeder.ensureSeeded(AppDatabase.instance);

  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const AutomagApp(),
    ),
  );
}
