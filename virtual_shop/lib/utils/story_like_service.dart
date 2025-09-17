import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class StoryLikeService {
  static String? _base() {
    final envServer = dotenv.env['SERVER_URL'] ?? '';
    if (envServer.isEmpty) return null;
    var b = envServer.trim();
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);
    return b;
  }

  static Future<Map<String, dynamic>> like(String storyId) async {
    final base = _base();
    if (base == null) throw Exception('SERVER_URL not configured');
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not signed in');
    final resp = await http.post(
      Uri.parse('$base/stories/$storyId/like'),
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (resp.statusCode >= 400) {
      throw Exception('Story like failed: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> unlike(String storyId) async {
    final base = _base();
    if (base == null) throw Exception('SERVER_URL not configured');
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not signed in');
    final resp = await http.delete(
      Uri.parse('$base/stories/$storyId/like'),
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (resp.statusCode >= 400) {
      throw Exception('Story unlike failed: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> status(String storyId) async {
    final base = _base();
    if (base == null) throw Exception('SERVER_URL not configured');
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not signed in');
    final resp = await http.get(
      Uri.parse('$base/stories/$storyId/like/status'),
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (resp.statusCode >= 400) {
      throw Exception(
        'Story like status failed: ${resp.statusCode} ${resp.body}',
      );
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> userStories(
    String userAuthId, {
    int limit = 50,
  }) async {
    final base = _base();
    if (base == null) throw Exception('SERVER_URL not configured');
    final uri = Uri.parse(
      '$base/stories?limit=$limit&user_auth_id=$userAuthId',
    );
    final resp = await http.get(uri);
    if (resp.statusCode >= 400) {
      throw Exception('Fetch stories failed: ${resp.statusCode} ${resp.body}');
    }
    final List<dynamic> data = jsonDecode(resp.body) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
