import 'part.dart';

class CartItem {
  final Part part;
  int quantity;

  CartItem({required this.part, this.quantity = 1});

  Map<String, dynamic> toJson() => {
        'name': part.name,
        'model': part.model,
        'price': part.price,
        'image': part.image,   // ДОБАВИЛИ
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      part: Part(
        name: json['name'],
        model: json['model'],
        price: json['price'],
        image: json['image'],   // ДОБАВИЛИ
      ),
      quantity: json['quantity'],
    );
  }
}
