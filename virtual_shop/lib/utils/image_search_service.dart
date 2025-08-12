import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/product.dart';

class ImageSearchService {
  static String get _baseUrl {
    final fromServer = dotenv.env['SERVER_URL']?.trim();
    final fromBackend = dotenv.env['BACKEND_URL']?.trim();
    final raw = (fromServer?.isNotEmpty == true)
        ? fromServer!
        : (fromBackend?.isNotEmpty == true
              ? fromBackend!
              : 'http://127.0.0.1:8000');
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static String _detectMime(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'image/jpeg';
    }
    return 'image/png';
  }

  static String _basenameNoExt(String path) {
    final String fileName = path.split('/').last.split('\\').last;
    final int dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }

  static Future<List<String>> searchImageIds({
    required Uint8List imageBytes,
    int limit = 3,
  }) async {
    final mime = _detectMime(imageBytes);
    final String b64 = base64Encode(imageBytes);
    final String dataUri = 'data:$mime;base64,$b64';
    final payload = {'base64_image': dataUri, 'limit': limit};
    final resp = await http.post(
      _uri('/image-search/search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (resp.statusCode != 200) {
      throw Exception('Image search failed: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final List<dynamic> ids = data['image_ids'] ?? [];
    return ids.map((e) => e.toString()).toList(growable: false);
  }

  static Future<List<Map<String, dynamic>>> _fetchAllProducts() async {
    final resp = await http.get(_uri('/products/'));
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch products: ${resp.statusCode} ${resp.body}',
      );
    }
    final List<dynamic> arr = jsonDecode(resp.body) as List<dynamic>;
    return arr.cast<Map<String, dynamic>>();
  }

  static Product _toProduct(Map<String, dynamic> json) {
    double _toDouble(dynamic v, [double def = 0]) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }

    return Product(
      name:
          json['name']?.toString() ??
          json['product_name']?.toString() ??
          'Product',
      image: json['image_url']?.toString() ?? '',
      rating: _toDouble(json['rating'], 0),
      price: _toDouble(json['price'], 0),
      category: json['category']?.toString() ?? '',
      weather: json['weather']?.toString() ?? '',
      temp: json['temp']?.toString() ?? '',
      event: json['event']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  static Future<List<Product>> searchProductsByImage({
    required Uint8List imageBytes,
    int limit = 3,
  }) async {
    final ids = await searchImageIds(imageBytes: imageBytes, limit: limit);
    if (ids.isEmpty) return [];

    final all = await _fetchAllProducts();
    // Map by basename for quick lookup
    final Map<String, Map<String, dynamic>> byBase = {
      for (final p in all) _basenameNoExt(p['image_url']?.toString() ?? ''): p,
    };

    final List<Product> results = [];
    final Set<String> used = {};
    for (final id in ids) {
      final key = id.trim();
      final json = byBase[key];
      if (json != null) {
        final img = json['image_url']?.toString() ?? '';
        if (!used.contains(img)) {
          results.add(_toProduct(json));
          used.add(img);
        }
      } else {
        final fallback = all.firstWhere(
          (p) => _basenameNoExt(
            p['image_url']?.toString() ?? '',
          ).toLowerCase().contains(key.toLowerCase()),
          orElse: () => {},
        );
        if (fallback.isNotEmpty) {
          final img = fallback['image_url']?.toString() ?? '';
          if (!used.contains(img)) {
            results.add(_toProduct(fallback));
            used.add(img);
          }
        }
      }
      if (results.length >= limit) break;
    }
    return results;
  }
}
