import 'dart:typed_data';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SupabaseService {
  static const String profileImageBucket = 'profile_image';

  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) {
    return supabase.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
  }

  static Future<AuthResponse> signInWithGoogle({
    required String webClientId,
    String? iosClientId,
  }) async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null) {
      throw const AuthException('No Access Token found.');
    }
    if (idToken == null) {
      throw const AuthException('No ID Token found.');
    }

    return supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  static Future<void> upsertUserProfile({
    String? id,
    required String email,
    String? name,
    String? phone,
    String? userType,
    String? profileImageUrl,
  }) async {
    final payload = <String, dynamic>{
      'email': email,
      if (id != null) 'auth_id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (userType != null) 'user_type': userType,
      if (profileImageUrl != null) 'profile_image': profileImageUrl,
    };

    try {
      if (id != null) {
        final updatedByAuth = await supabase
            .from('users')
            .update(payload)
            .eq('auth_id', id)
            .select('user_id');
        if (updatedByAuth.isNotEmpty) {
          return;
        }
      }

      final updatedByEmail = await supabase
          .from('users')
          .update(payload)
          .eq('email', email)
          .select('user_id');
      if (updatedByEmail.isNotEmpty) {
        return;
      }

      await supabase.from('users').insert(payload);
    } catch (_) {
      try {
        await supabase.from('users').insert(payload);
      } catch (_) {
        await supabase.from('users').update(payload).eq('email', email);
      }
    }
  }

  static Future<Map<String, dynamic>?> fetchUserProfile(String email) async {
    final currentId = supabase.auth.currentUser?.id;
    if (currentId != null) {
      final byAuth = await supabase
          .from('users')
          .select()
          .eq('auth_id', currentId)
          .order('user_id', ascending: false)
          .limit(1);
      if (byAuth.isNotEmpty) {
        return Map<String, dynamic>.from(byAuth.first as Map);
      }
    }

    final byEmail = await supabase
        .from('users')
        .select()
        .eq('email', email)
        .order('user_id', ascending: false)
        .limit(1);
    if (byEmail.isNotEmpty) {
      return Map<String, dynamic>.from(byEmail.first as Map);
    }
    return null;
  }

  static Future<bool> isProfileComplete(String email) async {
    final row = await fetchUserProfile(email);
    if (row == null) return false;
    final name = row['name'] as String?;
    final userType = row['user_type'] as String?;
    final dob = row['dob'];
    final hasDob = dob != null && dob.toString().isNotEmpty;
    return name != null &&
        name.isNotEmpty &&
        userType != null &&
        userType.isNotEmpty &&
        hasDob;
  }

  static Future<void> updateUserProfile({
    required String email,
    String? name,
    String? userType,
    String? gender,
    String? dobIso8601,
    String? phone,
    String? profileImageUrl,
  }) async {
    final dobValue = dobIso8601 != null && dobIso8601.isNotEmpty
        ? dobIso8601.split('T').first
        : null;
    final update = <String, dynamic>{
      if (name != null) 'name': name,
      if (userType != null) 'user_type': userType,
      if (phone != null) 'phone': phone,
      if (dobValue != null) 'dob': dobValue,
      if (profileImageUrl != null) 'profile_image': profileImageUrl,
    };
    if (update.isEmpty) return;
    final currentId = supabase.auth.currentUser?.id;
    if (currentId != null) {
      final updated = await supabase
          .from('users')
          .update(update)
          .eq('auth_id', currentId)
          .select('user_id');
      if (updated.isNotEmpty) {
        if (email.isNotEmpty) {
          await supabase
              .from('users')
              .update({'email': email})
              .eq('auth_id', currentId);
        }
      } else {
        await supabase.from('users').update(update).eq('email', email);
      }
    } else {
      await supabase.from('users').update(update).eq('email', email);
    }

    final meta = <String, dynamic>{
      if (gender != null) 'gender': gender,
      if (dobIso8601 != null) 'dob': dobIso8601,
      if (profileImageUrl != null) 'avatar_url': profileImageUrl,
      if (profileImageUrl != null) 'picture': profileImageUrl,
    };
    if (meta.isNotEmpty) {
      await updateAuthMetadata(meta);
    }
  }

  static Future<void> updateAuthMetadata(Map<String, dynamic> data) async {
    await supabase.auth.updateUser(UserAttributes(data: data));
  }

  static Future<String> uploadProfileImageBytes({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
  }) async {
    final userId = supabase.auth.currentUser?.id ?? 'anonymous';
    final ext = _extensionFromFilename(filename);
    final objectPath =
        'users/$userId/${DateTime.now().millisecondsSinceEpoch}${ext.isNotEmpty ? '.$ext' : ''}';

    await supabase.storage
        .from(profileImageBucket)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType ?? _inferMimeTypeFromExt(ext),
            upsert: true,
          ),
        );

    final publicUrl = supabase.storage
        .from(profileImageBucket)
        .getPublicUrl(objectPath);
    return publicUrl;
  }

  static Future<void> setProfileImageUrlForUser(
    String url, {
    String? email,
  }) async {
    await updateAuthMetadata({
      'avatar_url': url,
      'picture': url,
      'avatar_url_custom': url,
    });

    final candidates = <String>[
      'avatar_url',
      'profile_image',
      'profile_image_url',
      'image_url',
      'profile_img',
      'photo_url',
      'picture',
    ];
    for (final col in candidates) {
      final ok = await _tryUpdateUsersImageColumn(col, url, email: email);
      if (ok) break;
    }
  }

  static Future<bool> _tryUpdateUsersImageColumn(
    String column,
    String url, {
    String? email,
  }) async {
    try {
      final currentId = supabase.auth.currentUser?.id;
      if (currentId != null) {
        final updated = await supabase
            .from('users')
            .update({column: url})
            .eq('auth_id', currentId)
            .select('user_id');
        if (updated.isNotEmpty) return true;
      }
      if (email != null && email.isNotEmpty) {
        final updatedByEmail = await supabase
            .from('users')
            .update({column: url})
            .eq('email', email)
            .select('user_id');
        if (updatedByEmail.isNotEmpty) return true;
      }
    } catch (_) {}
    return false;
  }

  static String _extensionFromFilename(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  static String _inferMimeTypeFromExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'tif':
      case 'tiff':
        return 'image/tiff';
      case 'heic':
      case 'heif':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }
}
