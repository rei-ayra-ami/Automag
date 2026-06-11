import 'package:flutter/material.dart';
import '../models/part.dart';
import '../services/product_service.dart';
import 'part_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String query = '';
  String selectedCategory = 'Все';
  late Future<List<Part>> partsFuture;

  @override
  void initState() {
    super.initState();
    partsFuture = ProductService.fetchParts();
  }

  bool _matches(Part p) {
    final q = query.trim().toLowerCase();
    final byCategory =
        selectedCategory == 'Все' || p.category == selectedCategory;
    final bySearch = q.isEmpty ||
        p.name.toLowerCase().contains(q) ||
        p.brand.toLowerCase().contains(q) ||
        p.category.toLowerCase().contains(q) ||
        p.model.toLowerCase().contains(q);
    return byCategory && bySearch;
  }

  /// Выпадающие подсказки при вводе в поиск: до 6 совпадений по
  /// названию или бренду. Тап по подсказке открывает карточку товара.
  Widget _buildSuggestions(BuildContext context, List<Part> parts) {
    final q = query.trim().toLowerCase();
    final suggestions = parts
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q))
        .take(6)
        .toList();
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          for (final p in suggestions)
            ListTile(
              dense: true,
              leading: Icon(p.categoryIcon,
                  color: Theme.of(context).colorScheme.primary),
              title:
                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${p.brand} · ${p.category}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text('${formatPrice(p.price)} ₸',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                FocusScope.of(context).unfocus();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PartDetailScreen(part: p)),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Part>>(
      future: partsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                const Text('Не удалось загрузить каталог'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(
                      () => partsFuture = ProductService.fetchParts()),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final parts = snapshot.data!;
        final categories = <String>[
          'Все',
          ...(parts.map((p) => p.category).toSet().toList()..sort()),
        ];
        final filtered = parts.where(_matches).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Поиск по названию, бренду или категории',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                ),
                onChanged: (value) => setState(() => query = value),
              ),
            ),
            if (query.trim().isNotEmpty) _buildSuggestions(context, parts),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final selected = cat == selectedCategory;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => selectedCategory = cat),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Найдено: ${filtered.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Ничего не найдено'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        final f = ProductService.fetchParts();
                        setState(() => partsFuture = f);
                        await f;
                      },
                      child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.68,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _PartCard(part: filtered[index]);
                      },
                    ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PartCard extends StatelessWidget {
  final Part part;
  const _PartCard({required this.part});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PartDetailScreen(part: part)),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey.shade100,
                child: PartImage(part: part),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    part.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    part.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${formatPrice(part.price)} ₸',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Картинка детали: реальное фото, если есть; иначе иконка категории.
class PartImage extends StatelessWidget {
  final Part part;
  final double iconSize;
  const PartImage({super.key, required this.part, this.iconSize = 56});

  Widget _placeholder(BuildContext context) {
    return Center(
      child: Icon(
        part.categoryIcon,
        size: iconSize,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.55),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Сначала — фото, загруженное вручную (хранится в БД), затем ассет.
    final bytes = part.imageBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, _, __) => _placeholder(context),
      );
    }
    final img = part.image;
    if (img == null || img.isEmpty) {
      return _placeholder(context);
    }
    return Image.asset(
      img,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, _, __) => _placeholder(context),
    );
  }
}

/// Формат цены с разделением разрядов: 18900 -> 18 900
String formatPrice(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}
