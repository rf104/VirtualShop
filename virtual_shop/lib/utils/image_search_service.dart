import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/product.dart';

class ImageSearchService {
  static String get _baseUrl {
    final fromServer = dotenv.env['SERVER_URL']?.trim();
    final fromBackend = dotenv.env['BACKEND_URL']?.trim();
    String raw = (fromServer?.isNotEmpty == true)
        ? fromServer!
        : (fromBackend?.isNotEmpty == true
              ? fromBackend!
              : 'http://127.0.0.1:8000');
    // Remove accidental whitespace after scheme like 'http:// 127.0.0.1:8000'
    raw = raw.replaceFirst(RegExp(r'^(https?://)\s+'), r'$1');
    String url = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    // Map localhost to Android emulator loopback if applicable
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final uri = Uri.parse(url);
        if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
          url = uri.replace(host: dotenv.env['hostIp'] ??'192.168.0.154').toString(); 
        }
      }
    } catch (_) {}
    return url;
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

  static Future<List<Map<String, dynamic>>> _searchResultsRaw({
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
    final List<dynamic> results = data['results'] ?? [];
    return results.cast<Map<String, dynamic>>();
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

  // Removed unused _toProduct helper; using Product.fromJson instead.

  static Future<List<Product>> searchProductsByImage({
    required Uint8List imageBytes,
    int limit = 3,
  }) async {
    final raw = await _searchResultsRaw(imageBytes: imageBytes, limit: limit);
    final all = await _fetchAllProducts();
    // Build a map by product id for exact lookup
    final Map<String, Map<String, dynamic>> byId = {
      for (final p in all) (p['id']?.toString() ?? ''): p,
    };
    final List<Product> out = [];
    final Set<String> usedIds = {};
    for (final r in raw) {
      final pid = r['product_id']?.toString();
      if (pid == null || pid.isEmpty) continue;
      final p = byId[pid];
      if (p != null && !usedIds.contains(pid)) {
        out.add(Product.fromJson(p));
        usedIds.add(pid);
      }
      if (out.length >= limit) break;
    }

    // Fallback to legacy image_ids strategy if no results matched by id
    if (out.isEmpty) {
      final ids = await searchImageIds(imageBytes: imageBytes, limit: limit);
      if (ids.isEmpty) return [];
      final Map<String, Map<String, dynamic>> byBase = {
        for (final p in all)
          _basenameNoExt(p['image_url']?.toString() ?? ''): p,
      };
      for (final id in ids) {
        final key = id.trim();
        final json = byBase[key];
        if (json != null) out.add(Product.fromJson(json));
        if (out.length >= limit) break;
      }
    }
    return out;
  }
}
