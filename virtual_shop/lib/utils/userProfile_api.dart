import 'dart:convert';
import 'dart:io' show File;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static const String baseUrl = "http://10.103.137.37:8000";

  // Fetch a specific user by ID
  static Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    final url = Uri.parse('$baseUrl/users/$userId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // returns user info as Map
    } else {
      throw Exception("Error: ${response.reasonPhrase}");
    }
  }

  // Get current user profile
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    final token = Supabase.instance.client.auth.currentSession?.accessToken;

    if (userId == null || token == null) throw Exception('Not signed in');

    final url = Uri.parse('$baseUrl/users/$userId');

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

  //updateSelf
  static Future<Map<String, dynamic>?> updateSelf({
    String? name,
    String? email,
    String? phone,
    String? dob,
    String? address,
    File? avatar,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    final token = Supabase.instance.client.auth.currentSession?.accessToken;

    if (userId == null || token == null) throw Exception('Not signed in');

    final url = Uri.parse('$baseUrl/users/$userId');

    final request = http.MultipartRequest('PUT', url);

    // Add authorization header
    request.headers['Authorization'] = 'Bearer $token';

    if (name != null && name.isNotEmpty) request.fields['name'] = name;
    if (email != null && email.isNotEmpty) request.fields['email'] = email;
    if (phone != null && phone.isNotEmpty) request.fields['phone'] = phone;
    if (dob != null && dob.isNotEmpty) request.fields['dob'] = dob;
    if (address != null && address.isNotEmpty)
      request.fields['address'] = address;

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
      return jsonDecode(response.body);
    } else {
      throw Exception('Update failed: ${response.statusCode} ${response.body}');
    }
  }
}
