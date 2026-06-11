import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import 'catalog_screen.dart' show formatPrice;

/// Способ получения заказа.
enum DeliveryMethod { delivery, pickup }

/// Экран оформления заказа: контактные данные + способ получения.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  DeliveryMethod _method = DeliveryMethod.delivery;
  bool _submitting = false;

  // Адрес пункта самовывоза (для демонстрации).
  static const String _pickupPoint =
      'г. Алматы, ул. Толе би 285, склад «Automag», ежедневно 9:00–19:00';

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  /// Подставляет имя и телефон из профиля, чтобы не вводить заново.
  Future<void> _prefillFromProfile() async {
    final user = await AuthService.currentUser();
    if (!mounted || user == null) return;
    setState(() {
      if (_nameController.text.isEmpty && (user.name ?? '').isNotEmpty) {
        _nameController.text = user.name!;
      }
      if (_phoneController.text.isEmpty && (user.phone ?? '').isNotEmpty) {
        _phoneController.text = user.phone!;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit(CartProvider cart) async {
    if (!_formKey.currentState!.validate()) return;
    if (_submitting) return;

    final isPickup = _method == DeliveryMethod.pickup;
    final customer = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    setState(() => _submitting = true);
    final orderId = await OrderService.createOrder(
      items: cart.items,
      customerName: customer,
      phone: phone,
      deliveryMethod: isPickup ? 'pickup' : 'delivery',
      address: isPickup ? null : address,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось оформить заказ. '
              'Войдите в аккаунт и попробуйте снова.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Заказ №$orderId оформлен'),
        content: Text(
          isPickup
              ? 'Спасибо, $customer! Заказ №$orderId готовится к самовывозу:'
                  '\n\n$_pickupPoint\n\n'
                  'Статус заказа можно отслеживать в разделе «Мои заказы» '
                  '(вкладка «Профиль»). Мы позвоним вам по номеру $phone.'
              : 'Спасибо, $customer! Заказ №$orderId будет доставлен по адресу:'
                  '\n\n$address\n\n'
                  'Статус заказа можно отслеживать в разделе «Мои заказы» '
                  '(вкладка «Профиль»). Мы позвоним вам по номеру $phone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(dialogContext); // закрыть диалог
              Navigator.pop(context); // вернуться из оформления в корзину
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isPickup = _method == DeliveryMethod.pickup;

    return Scaffold(
      appBar: AppBar(title: const Text('Оформление заказа')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Контактные данные',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Имя и фамилия',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Введите имя' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Номер телефона',
                hintText: '+7 (___) ___-__-__',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.length < 10) return 'Введите корректный номер';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text('Способ получения',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  RadioListTile<DeliveryMethod>(
                    value: DeliveryMethod.delivery,
                    groupValue: _method,
                    onChanged: (v) => setState(() => _method = v!),
                    title: const Text('Доставка'),
                    subtitle: const Text('Курьер привезёт по вашему адресу'),
                    secondary: const Icon(Icons.local_shipping_outlined),
                  ),
                  const Divider(height: 1),
                  RadioListTile<DeliveryMethod>(
                    value: DeliveryMethod.pickup,
                    groupValue: _method,
                    onChanged: (v) => setState(() => _method = v!),
                    title: const Text('Самовывоз'),
                    subtitle: const Text('Забрать со склада бесплатно'),
                    secondary: const Icon(Icons.storefront_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (isPickup)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.place_outlined, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(_pickupPoint, style: TextStyle(height: 1.4)),
                    ),
                  ],
                ),
              )
            else
              TextFormField(
                controller: _addressController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Адрес доставки',
                  hintText: 'Город, улица, дом, квартира',
                  prefixIcon: Icon(Icons.home_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) {
                  if (isPickup) return null;
                  return (v == null || v.trim().isEmpty)
                      ? 'Введите адрес доставки'
                      : null;
                },
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Товаров: ${cart.totalCount}',
                    style: TextStyle(color: Colors.grey.shade700)),
                Text(
                  'Итого: ${formatPrice(cart.totalPrice)} ₸',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: (cart.items.isEmpty || _submitting)
                    ? null
                    : () => _submit(cart),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Подтвердить заказ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
