import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/part.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  CartProvider() {
    loadCart();
  }

  void add(Part part) {
    final index = _items.indexWhere((i) => i.part.name == part.name);

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(part: part));
    }

    saveCart();
    notifyListeners();
  }

  void decrease(Part part) {
    final index = _items.indexWhere((i) => i.part.name == part.name);

    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
    }

    saveCart();
    notifyListeners();
  }

  int get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.part.price * item.quantity);

  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _items.map((e) => jsonEncode(e.toJson())).toList();
    prefs.setStringList('cart', data);
  }

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('cart');

    if (data != null) {
      _items.clear();
      _items.addAll(data.map((e) => CartItem.fromJson(jsonDecode(e))));
      notifyListeners();
    }
  }
}
