import 'dart:convert';
import 'dart:io' show File;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static const String baseUrl = "http://192.168.0.102:8000";

  // Fetch a specific user by ID
  static Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    final url = Uri.parse('$baseUrl/users/$userId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // returns user info as Map
    } else {
      print("Error: ${response.reasonPhrase}");
      return null;
    }
  }

  //updateSelf
  static Future<Map<String, dynamic>?> updateSelf({
    String? name,
    String? email,
    String? phone,
    File? avatar,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    final authId = user?.id;
    if (authId == null) {
      throw Exception('Not signed in');
    }

    final url = Uri.parse('$baseUrl/profile/update');

    final request = http.MultipartRequest('PUT', url);
    request.fields['auth_id'] = authId;
    if (name != null) request.fields['name'] = name;
    if (email != null) request.fields['email'] = email;
    if (phone != null) request.fields['phone'] = phone;

    if (avatar != null) {
      final mimeType = lookupMimeType(avatar.path) ?? 'application/octet-stream';
      final mimeParts = mimeType.split('/');
      final fileStream = http.ByteStream(avatar.openRead());
      final fileLength = await avatar.length();

      final multipartFile = http.MultipartFile(
        'avatar',
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
      return jsonDecode(response.body); // returns updated user info as Map
    } else {
      print("Error: ${response.reasonPhrase}");
      return null;
    }
  }
}