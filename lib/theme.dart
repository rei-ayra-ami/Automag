import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
  ),
  scaffoldBackgroundColor: Colors.blue.shade50,
  appBarTheme: const AppBarTheme(
    centerTitle: true,
  ),
);
