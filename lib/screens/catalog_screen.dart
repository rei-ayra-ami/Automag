import 'package:flutter/material.dart';
import '../models/part.dart';
import 'part_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String query = '';

  final parts = [
    Part(
      name: 'Тормозные колодки',
      model: 'Toyota Camry',
      price: 12000,
      image: 'assets/images/parts/brake_pads.png',
    ),
    Part(
      name: 'Масляный фильтр',
      model: 'Nissan Sunny',
      price: 3500,
      image: 'assets/images/parts/oil_filter.png',
    ),
    Part(
      name: 'Свечи зажигания',
      model: 'Honda Accord',
      price: 8000,
      image: 'assets/images/parts/spark_plug.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = parts.where((p) =>
        p.name.toLowerCase().contains(query.toLowerCase()) ||
        p.model.toLowerCase().contains(query.toLowerCase())).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Поиск по названию или авто',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => query = value),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final part = filtered[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PartDetailScreen(part: part),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              part.image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          part.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          part.model,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${part.price} ₸',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
