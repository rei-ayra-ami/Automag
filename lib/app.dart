import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart';

class AutomagApp extends StatelessWidget {
  const AutomagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Automag',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const HomeScreen(),
    );
  }
}
