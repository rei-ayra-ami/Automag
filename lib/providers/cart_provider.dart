import 'package:flutter/material.dart';
import '../models/part.dart';

class CartProvider extends ChangeNotifier {
  final List<Part> _items = [];

  List<Part> get items => _items;

  int get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.price);

  void add(Part part) {
    _items.add(part);
    notifyListeners();
  }

  void remove(Part part) {
    _items.remove(part);
    notifyListeners();
  }
}
