import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/product.dart';

class RelatedProductsService {
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
          url = uri
              .replace(host: dotenv.env['hostIp'] ?? '10.103.137.37')
              .toString();
        }
      }
    } catch (_) {}
    return url;
  }

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Future<List<Product>> fetchRelatedProducts({
    required String productId,
    int limit = 6,
  }) async {
    final resp = await http.get(
      _uri('/products/$productId/related?limit=$limit'),
    );
    if (resp.statusCode != 200) {
      throw Exception('Related fetch failed: ${resp.statusCode} ${resp.body}');
    }
    final Map<String, dynamic> jsonBody = jsonDecode(resp.body);
    debugPrint('Related fetch response: $jsonBody');
    final List<dynamic> arr = (jsonBody['results'] as List?) ?? const [];
    final List<Product> out = [];
    for (final item in arr) {
      if (item is Map<String, dynamic>) {
        debugPrint('Related product item: $item');
        Product p = Product.fromJson(item);
        out.add(p);
      } else if (item is Map) {
        out.add(Product.fromJson(item.cast<String, dynamic>()));
      }
    }
    return out;
  }
}
