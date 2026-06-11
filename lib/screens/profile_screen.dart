import 'package:flutter/material.dart';
import '../db/database.dart';
import '../services/auth_service.dart';
import 'admin_add_product_screen.dart';
import 'admin_orders_screen.dart';
import 'login_screen.dart';
import 'my_orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<User?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = AuthService.currentUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data;
        final isAdmin = user?.role == 'admin';
        final displayName = (user?.name?.isNotEmpty ?? false)
            ? user!.name!
            : (user?.email ?? 'Пользователь');

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.person,
                  size: 52,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                displayName,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                isAdmin ? 'Администратор Automag' : 'Покупатель Automag',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),

            // --- Заказы и (для админа) управление магазином ---
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Мои заказы'),
                    subtitle: const Text('История покупок и статусы'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                    ),
                  ),
                  if (isAdmin) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.fact_check_outlined),
                      title: const Text('Управление заказами'),
                      subtitle: const Text('Все заказы и смена статусов'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminOrdersScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.add_box_outlined),
                      title: const Text('Добавить товар'),
                      subtitle: const Text('Регистрация новой запчасти'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminAddProductScreen()),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

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
            const SizedBox(height: 24),

            OutlinedButton.icon(
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
          ],
        );
      },
    );
  }
}
