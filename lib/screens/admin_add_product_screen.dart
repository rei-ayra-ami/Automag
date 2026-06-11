import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/product_service.dart';

/// Регистрация нового товара в базе данных (доступно администратору).
class AdminAddProductScreen extends StatefulWidget {
  const AdminAddProductScreen({super.key});

  @override
  State<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends State<AdminAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _category = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _stock = TextEditingController(text: '50');

  bool _saving = false;
  Uint8List? _imageBytes;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // нужно, чтобы получить байты (в т.ч. в web)
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    setState(() => _imageBytes = bytes);
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _model.dispose();
    _category.dispose();
    _price.dispose();
    _description.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    await ProductService.addProduct(
      name: _name.text.trim(),
      brand: _brand.text.trim(),
      model: _model.text.trim().isEmpty ? 'Универсальный' : _model.text.trim(),
      category:
          _category.text.trim().isEmpty ? 'Прочее' : _category.text.trim(),
      price: int.parse(_price.text.trim()),
      description: _description.text.trim(),
      stock: int.tryParse(_stock.text.trim()) ?? 0,
      imageBytes: _imageBytes,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Товар «${_name.text.trim()}» добавлен в каталог')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить товар')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Фото товара (необязательно). Хранится прямо в базе данных.
            GestureDetector(
              onTap: _saving ? null : _pickImage,
              child: Container(
                height: 170,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageBytes != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_imageBytes!, fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                tooltip: 'Убрать фото',
                                icon: const Icon(Icons.close,
                                    size: 18, color: Colors.white),
                                onPressed: () =>
                                    setState(() => _imageBytes = null),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 40, color: Colors.grey.shade500),
                          const SizedBox(height: 8),
                          Text('Прикрепить фото',
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _field(_name, 'Название', icon: Icons.label_outline, required: true),
            _field(_brand, 'Производитель', icon: Icons.factory_outlined),
            _field(_model, 'Применимость (для каких авто)',
                icon: Icons.directions_car_outlined),
            _field(_category, 'Категория',
                icon: Icons.category_outlined,
                hint: 'Например: Тормозная система'),
            _field(
              _price,
              'Цена, ₸',
              icon: Icons.payments_outlined,
              keyboard: TextInputType.number,
              required: true,
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return 'Введите цену числом';
                return null;
              },
            ),
            _field(
              _stock,
              'Количество на складе',
              icon: Icons.inventory_2_outlined,
              keyboard: TextInputType.number,
            ),
            _field(_description, 'Описание',
                icon: Icons.description_outlined, maxLines: 3),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_outlined),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saving ? null : _save,
                label: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Сохранить товар'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    IconData? icon,
    String? hint,
    TextInputType? keyboard,
    int maxLines = 1,
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: const OutlineInputBorder(),
        ),
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? 'Заполните это поле'
                    : null
                : null),
      ),
    );
  }
}
