import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductApi {
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
          url = uri.replace(host: '192.168.0.154').toString();
        }
      }
    } catch (_) {}
    return url;
  }

  static Future<void> createProduct({
    required String name,
    required String description,
    required String category,
    String? brand,
    required double price,
    required int stock,
    String condition = 'New',
    double? weightKg,
    String? dimensions,
    bool isFeatured = false,
    bool isInStock = true,
    required List<File> images,
    List<String>? imageTags,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    final authId = user?.id;
    if (authId == null) {
      throw Exception('Not signed in');
    }

    print('Creating product with ${images.length} images');

    final uri = Uri.parse('$_baseUrl/products');

    print('POST $uri');

    final req = http.MultipartRequest('POST', uri);
    req.fields['auth_id'] = authId;
    req.fields['name'] = name;
    req.fields['description'] = description;
    req.fields['category'] = category;
    if (brand != null && brand.isNotEmpty) req.fields['brand'] = brand;
    req.fields['price'] = price.toString();
    req.fields['stock'] = stock.toString();
    req.fields['condition'] = condition;
    if (weightKg != null) req.fields['weight_kg'] = weightKg.toString();
    if (dimensions != null && dimensions.isNotEmpty) {
      req.fields['dimensions'] = dimensions;
    }
    req.fields['is_featured'] = isFeatured.toString();
    req.fields['is_in_stock'] = isInStock.toString();
    if (imageTags != null && imageTags.isNotEmpty) {
      req.fields['image_tags'] = imageTags.join(',');
    }

    for (final file in images) {
      final mime = lookupMimeType(file.path) ?? 'image/jpeg';
      final stream = http.ByteStream(Stream.castFrom(file.openRead()));
      final length = await file.length();
      final part = http.MultipartFile(
        'files',
        stream,
        length,
        filename: p.basename(file.path),
        contentType: MediaType.parse(mime),
      );
      req.files.add(part);
    }

    final resp = await req.send();
    final body = await resp.stream.bytesToString();
    if (resp.statusCode != 200) {
      throw Exception('Create product failed: ${resp.statusCode} $body');
    }
  }
}
