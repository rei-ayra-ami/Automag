import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/part.dart';

class ApiService {
  static const url = 'https://dummyjson.com/products';

  static Future<List<Part>> fetchParts() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List products = data['products'];

      return products.map((e) => Part.fromJson(e)).toList();
    } else {
      throw Exception('Ошибка загрузки');
    }
  }
}
