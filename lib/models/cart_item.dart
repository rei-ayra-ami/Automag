import 'part.dart';

class CartItem {
  final Part part;
  int quantity;

  CartItem({required this.part, this.quantity = 1});

  Map<String, dynamic> toJson() => {
        'part': part.toJson(),
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      part: Part.fromJson(json['part'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );
  }
}
