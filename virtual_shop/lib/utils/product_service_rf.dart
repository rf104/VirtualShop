import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/product_rf.dart'; // import your Product model

class ProductService {
  // final String baseUrl = "http://10.103.130.4:8000"; // change to your backend

  final String baseUrl = "http://${dotenv.env['hostIp']}:${dotenv.env['PORT']}";

  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products/'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load products");
    }
  }
}
