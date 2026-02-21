class Part {
  final String name;
  final String model;
  final int price;
  final String image;

  Part({
    required this.name,
    required this.model,
    required this.price,
    required this.image,
  });

  factory Part.fromJson(Map<String, dynamic> json) {
    return Part(
      name: json['title'],
      model: 'Universal', 
      price: json['price'],
      image: json['thumbnail'],
    );
  }
}
