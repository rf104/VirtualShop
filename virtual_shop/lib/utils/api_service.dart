import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/seller.dart';

class ApiService {
  static const String baseUrl = "http://192.168.0.154:8000";

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

  // Assistant chat: send messages and get reply
  static Future<String> assistantChat(
    List<Map<String, String>> messages,
  ) async {
    final url = Uri.parse('$baseUrl/assistant/chat');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'messages': messages}),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return (data['reply'] as String?) ?? '';
    } else {
      throw Exception(
        'Assistant error: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }
}
