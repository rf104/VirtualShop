import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
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
              .replace(host: dotenv.env['hostIp'] ?? '192.168.0.154')
              .toString();
        }
      }
    } catch (_) {}
    return url;
  }

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Future<Map<String, dynamic>> fetchReviews({
    required String productId,
    int? limit,
  }) async {
    final q = limit != null ? '?limit=$limit' : '';
    final resp = await http.get(_uri('/products/$productId/reviews$q'));
    if (resp.statusCode != 200) {
      throw Exception('Fetch reviews failed: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<void> submitReview({
    required String productId,
    required int rating,
    required String review,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
    if (jwt == null || jwt.isEmpty) {
      throw Exception('Missing auth token');
    }
    final resp = await http.post(
      _uri('/products/$productId/reviews'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode({'rating': rating, 'review': review}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Submit review failed: ${resp.statusCode} ${resp.body}');
    }
  }
}
