import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class Part {
  final String id;
  final String name;
  final String brand; // производитель
  final String model; // применимость: "Подходит для"
  final String category;
  final int price;
  final String description;
  final Map<String, String> specs; // характеристики
  final String? image; // путь к ассету или null
  final Uint8List? imageBytes; // фото, загруженное вручную (хранится в БД)

  Part({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.category,
    required this.price,
    required this.description,
    required this.specs,
    this.image,
    this.imageBytes,
  });

  factory Part.fromJson(Map<String, dynamic> json) {
    final rawBytes = json['imageBytes'] as String?;
    return Part(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? 'Универсальный',
      category: json['category'] as String? ?? 'Прочее',
      price: (json['price'] as num).round(),
      description: json['description'] as String? ?? '',
      specs: (json['specs'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toString())),
      image: json['image'] as String?,
      imageBytes:
          (rawBytes != null && rawBytes.isNotEmpty) ? base64Decode(rawBytes) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'model': model,
        'category': category,
        'price': price,
        'description': description,
        'specs': specs,
        'image': image,
        if (imageBytes != null) 'imageBytes': base64Encode(imageBytes!),
      };

  /// Иконка категории — показывается в карточке, если у товара нет фото.
  IconData get categoryIcon {
    switch (category) {
      case 'Тормозная система':
        return Icons.album;
      case 'Двигатель':
        return Icons.settings;
      case 'Фильтры':
        return Icons.filter_alt;
      case 'Зажигание':
        return Icons.bolt;
      case 'Трансмиссия':
        return Icons.sync;
      case 'Электрика':
        return Icons.battery_charging_full;
      case 'Подвеска':
        return Icons.airline_seat_legroom_reduced;
      case 'Охлаждение':
        return Icons.ac_unit;
      case 'Кузов и оптика':
        return Icons.lightbulb;
      case 'Масла и жидкости':
        return Icons.water_drop;
      default:
        return Icons.build;
    }
  }
}
