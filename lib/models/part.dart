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
  });

  factory Part.fromJson(Map<String, dynamic> json) {
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
