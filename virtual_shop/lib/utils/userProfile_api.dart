import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static String get baseUrl {
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
          final hostIp = dotenv.env['hostIp']?.trim() ?? '192.168.0.102';
          print(
            'DEBUG: Using hostIp = $hostIp from env: ${dotenv.env['hostIp']}',
          );
          url = uri.replace(host: hostIp).toString();
          print('DEBUG: Final URL = $url');
        }
      }
    } catch (_) {}
    return url;
  }

  // Get current user profile using auth_id
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    final authId = user?.id;
    final token = Supabase.instance.client.auth.currentSession?.accessToken;

    if (authId == null || token == null) throw Exception('Not signed in');

    final url = Uri.parse('$baseUrl/users/$authId');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed to load profile: ${response.statusCode} ${response.body}',
      );
    }
  }

  // Update current user profile using auth_id
  static Future<Map<String, dynamic>?> updateSelf({
    String? name,
    String? email,
    String? phone,
    String? dob,
    String? address,
    File? avatar,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    final authId = user?.id;
    final token = Supabase.instance.client.auth.currentSession?.accessToken;

    if (authId == null || token == null) throw Exception('Not signed in');

    final url = Uri.parse('$baseUrl/users/$authId');
    final request = http.MultipartRequest('PUT', url);

    // Add authorization header
    request.headers['Authorization'] = 'Bearer $token';

    // Add form fields
    if (name != null && name.isNotEmpty) request.fields['name'] = name;
    if (email != null && email.isNotEmpty) request.fields['email'] = email;
    if (phone != null && phone.isNotEmpty) request.fields['phone'] = phone;
    if (dob != null && dob.isNotEmpty) request.fields['dob'] = dob;
    if (address != null && address.isNotEmpty)
      request.fields['address'] = address;

    // Add profile image if provided
    if (avatar != null) {
      final mimeType =
          lookupMimeType(avatar.path) ?? 'application/octet-stream';
      final mimeParts = mimeType.split('/');
      final fileStream = http.ByteStream(avatar.openRead());
      final fileLength = await avatar.length();

      final multipartFile = http.MultipartFile(
        'profile_image',
        fileStream,
        fileLength,
        filename: p.basename(avatar.path),
        contentType: MediaType(mimeParts[0], mimeParts[1]),
      );
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      // Return the updated data if available
      if (result['data'] != null &&
          result['data'] is List &&
          result['data'].isNotEmpty) {
        return result['data'][0] as Map<String, dynamic>;
      }

      return result as Map<String, dynamic>;
    } else {
      throw Exception('Update failed: ${response.statusCode} ${response.body}');
    }
  }
}
