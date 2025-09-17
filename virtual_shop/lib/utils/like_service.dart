import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:virtual_shop/models/product.dart';

class LikeService {
  static String? _base() {
    final envServer = dotenv.env['SERVER_URL'] ?? '';
    if (envServer.isEmpty) return null;
    var b = envServer;
    if (b.endsWith('/rest/v1')) {
      b = b.substring(0, b.length - '/rest/v1'.length);
    }
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);
    return b;
  }

  static Future<bool> likeProduct(String productId) async {
    final base = _base();
    if (base == null) throw Exception('SERVER_URL not configured');
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not signed in');
    final uri = Uri.parse('$base/products/$productId/like');
    final resp = await http.post(
      uri,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (resp.statusCode >= 400) {
      throw Exception('Like failed: ${resp.statusCode} ${resp.body}');
    }
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    return map['liked'] == true;
  }

  static Future<bool> unlikeProduct(String productId) async {
    final base = _base();
    if (base == null) throw Exception('SERVER_URL not configured');
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not signed in');
    final uri = Uri.parse('$base/products/$productId/like');
    final resp = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (resp.statusCode >= 400) {
      throw Exception('Unlike failed: ${resp.statusCode} ${resp.body}');
    }
    return true;
  }

  static Future<bool> isLiked(String productId) async {
    final base = _base();
    if (base == null) return false;
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return false;
    final uri = Uri.parse('$base/products/$productId/like/status');
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (resp.statusCode >= 400) return false;
    try {
      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      return map['liked'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Product>> fetchLikedProducts() async {
    final base = _base();
    if (base == null) throw Exception('SERVER_URL not configured');
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not signed in');
    final uri = Uri.parse('$base/liked-products');
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (resp.statusCode >= 400) {
      throw Exception(
        'Fetch liked products failed: ${resp.statusCode} ${resp.body}',
      );
    }
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = (map['products'] as List?) ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }
}
