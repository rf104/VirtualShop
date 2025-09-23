import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminApi {
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

  static Future<bool> isAdmin() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return false;
    final uri = Uri.parse('$_baseUrl/admin/me');
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (resp.statusCode != 200) return false;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['is_admin'] == true;
  }

  static Future<Map<String, dynamic>> adminMe() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return {'is_admin': false};
    final uri = Uri.parse('$_baseUrl/admin/me');
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (resp.statusCode != 200) return {'is_admin': false};
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data;
  }

  static Future<List<Map<String, dynamic>>> fetchPendingProducts({
    String status = 'pending',
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return [];
    final uri = Uri.parse('$_baseUrl/admin/moderation/products?status=$status');
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch products: ${resp.statusCode} ${resp.body}',
      );
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    return items;
  }

  static Future<List<Map<String, dynamic>>> fetchPendingStories({
    String status = 'pending',
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return [];
    final uri = Uri.parse('$_baseUrl/admin/moderation/stories?status=$status');
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch stories: ${resp.statusCode} ${resp.body}',
      );
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    return items;
  }

  static Future<void> approveProduct(String id) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    final uri = Uri.parse('$_baseUrl/admin/moderation/products/$id/approve');
    final resp = await http.post(
      uri,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (resp.statusCode >= 300) {
      throw Exception('Approve failed: ${resp.statusCode} ${resp.body}');
    }
  }

  static Future<void> rejectProduct(String id, {String reason = ''}) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    final uri = Uri.parse('$_baseUrl/admin/moderation/products/$id/reject');
    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reason': reason}),
    );
    if (resp.statusCode >= 300) {
      throw Exception('Reject failed: ${resp.statusCode} ${resp.body}');
    }
  }

  static Future<void> approveStory(String id) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    final uri = Uri.parse('$_baseUrl/admin/moderation/stories/$id/approve');
    final resp = await http.post(
      uri,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (resp.statusCode >= 300) {
      throw Exception('Approve failed: ${resp.statusCode} ${resp.body}');
    }
  }

  static Future<void> rejectStory(String id, {String reason = ''}) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    final uri = Uri.parse('$_baseUrl/admin/moderation/stories/$id/reject');
    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reason': reason}),
    );
    if (resp.statusCode >= 300) {
      throw Exception('Reject failed: ${resp.statusCode} ${resp.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchProductComments(
    String productId,
  ) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return [];
    final uri = Uri.parse(
      '$_baseUrl/admin/moderation/products/$productId/comments',
    );
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch comments: ${resp.statusCode} ${resp.body}',
      );
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final items =
        (data['comments'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];
    return items;
  }

  static Future<Map<String, dynamic>> addProductComment(
    String productId, {
    required String message,
    String visibility = 'uploader',
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return {"ok": false};
    final uri = Uri.parse(
      '$_baseUrl/admin/moderation/products/$productId/comments',
    );
    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'message': message, 'visibility': visibility}),
    );
    if (resp.statusCode >= 300) {
      throw Exception('Failed to add comment: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
