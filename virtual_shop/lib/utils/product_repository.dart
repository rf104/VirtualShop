import 'dart:io' show Platform;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:virtual_shop/models/product.dart';

class ProductRepository {
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
          url = uri.replace(host: '192.168.0.154').toString();
        }
      }
    } catch (_) {}
    return url;
  }

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Future<List<Product>> fetchAll() async {
    final resp = await http.get(_uri('/products/'));
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch products: ${resp.statusCode} ${resp.body}',
      );
    }
    final List<dynamic> arr = jsonDecode(resp.body) as List<dynamic>;
    return arr.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }
}
