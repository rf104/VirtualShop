import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/seller.dart';

class ApiService {
  static const String baseUrl = "http://192.168.0.102:8000";

  // Fetch all sellers
  static Future<List<Seller>> getAllSellers() async {
    final url = Uri.parse('$baseUrl/sellers');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Seller.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch sellers: ${response.reasonPhrase}");
    }
  }
}
