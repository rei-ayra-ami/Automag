import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

class AutomagApp extends StatelessWidget {
  const AutomagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Automag',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: FutureBuilder(
        future: AuthService.isLoggedIn(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data! ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
