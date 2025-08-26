import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class CartApi {
  static String get _baseUrl {
    final fromServer = dotenv.env['SERVER_URL']?.trim();
    final fromBackend = dotenv.env['BACKEND_URL']?.trim();
    String raw = (fromServer?.isNotEmpty == true)
        ? fromServer!
        : (fromBackend?.isNotEmpty == true
              ? fromBackend!
              : 'http://127.0.0.1:8000');
    raw = raw.replaceFirst(RegExp(r'^(https?://)\s+'), r'$1');
    String url = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final uri = Uri.parse(url);
        if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
          url = uri.replace(host: '10.103.134.151').toString();
        }
      }
    } catch (_) {}
    return url;
  }

  static Future<Map<String, dynamic>> addToCart({
    required String productId,
    int quantity = 1,
  }) async {
    final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
    if (jwt == null) {
      throw Exception('Not signed in');
    }
    final uri = Uri.parse('$_baseUrl/cart/add');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode({'product_id': productId, 'quantity': quantity}),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Add to cart failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<List<dynamic>> getCart() async {
    final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
    if (jwt == null) {
      throw Exception('Not signed in');
    }
    final uri = Uri.parse('$_baseUrl/cart');
    final resp = await http.get(uri, headers: {'Authorization': 'Bearer $jwt'});
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return (data['items'] as List?) ?? const [];
    }
    throw Exception('Get cart failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<dynamic> checkout() async {
    final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
    if (jwt == null) {
      throw Exception('Not signed in');
    }
    final uri = Uri.parse('$_baseUrl/cart/checkout');
    final resp = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $jwt'},
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        return jsonDecode(resp.body);
      } catch (_) {
        return resp.body;
      }
    }
    throw Exception('Checkout failed: ${resp.statusCode} ${resp.body}');
  }
}
