import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 44,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            child: Icon(
              Icons.person,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<String?>(
            future: AuthService.currentLogin(),
            builder: (context, snapshot) {
              final login = snapshot.data ?? 'Пользователь';
              return Text(
                login,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Покупатель Automag',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.local_shipping_outlined),
                  title: Text('Доставка'),
                  subtitle: Text('По всему Казахстану, 1–3 дня'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.support_agent_outlined),
                  title: Text('Поддержка'),
                  subtitle: Text('+7 (700) 000-00-00'),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Выйти из аккаунта'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                await AuthService.logout();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
