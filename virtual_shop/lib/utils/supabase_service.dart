import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SupabaseService {
  /// Sign in with email & password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  /// Sign up with email & password + metadata
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

  /// Native Google sign-in using google_sign_in + signInWithIdToken
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

  /// Upsert into public.users table after sign up/login
  static Future<void> upsertUserProfile({
    String? id,
    required String email,
    String? name,
    String? phone,
    String? userType,
  }) async {
    // Build payload without assuming an 'id' column exists in public.users
    final payload = <String, dynamic>{
      'email': email,
      if (id != null) 'auth_id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (userType != null) 'user_type': userType,
    };

    // Robust upsert: select → update if exists → else insert
    try {
      // 1) Try update by auth_id if available
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

      // 2) Try update by email
      final updatedByEmail = await supabase
          .from('users')
          .update(payload)
          .eq('email', email)
          .select('user_id');
      if (updatedByEmail.isNotEmpty) {
        return;
      }

      // 3) Insert a new row
      await supabase.from('users').insert(payload);
    } catch (_) {
      // Fallback to insert; if it fails (e.g., duplicate), try update
      try {
        await supabase.from('users').insert(payload);
      } catch (_) {
        await supabase.from('users').update(payload).eq('email', email);
      }
    }
  }

  /// Fetch user profile row from public.users
  static Future<Map<String, dynamic>?> fetchUserProfile(String email) async {
    // Try by auth_id first to avoid duplicates by email
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

  /// Check if profile has required fields
  static Future<bool> isProfileComplete(String email) async {
    final row = await fetchUserProfile(email);
    if (row == null) return false;
    final name = row['name'] as String?;
    final userType = row['user_type'] as String?;
    final dob = row['dob'];
    final hasDob = dob != null && dob.toString().isNotEmpty;
    // Require fields that exist in public.users schema (now includes dob)
    return name != null &&
        name.isNotEmpty &&
        userType != null &&
        userType.isNotEmpty &&
        hasDob;
  }

  /// Update profile fields in public.users
  static Future<void> updateUserProfile({
    required String email,
    String? name,
    String? userType,
    String? gender,
    String? dobIso8601,
    String? phone,
  }) async {
    final dobValue = dobIso8601 != null && dobIso8601.isNotEmpty
        ? dobIso8601.split('T').first
        : null;
    final update = <String, dynamic>{
      if (name != null) 'name': name,
      if (userType != null) 'user_type': userType,
      if (phone != null) 'phone': phone,
      if (dobValue != null) 'dob': dobValue,
    };
    if (update.isEmpty) return;
    // Prefer updating by auth_id if available, else by email
    final currentId = supabase.auth.currentUser?.id;
    if (currentId != null) {
      final updated = await supabase
          .from('users')
          .update(update)
          .eq('auth_id', currentId)
          .select('user_id');
      if (updated.isNotEmpty) {
        // also ensure email field is synced if provided
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

    // Persist non-schema fields to auth metadata instead
    final meta = <String, dynamic>{
      if (gender != null) 'gender': gender,
      if (dobIso8601 != null) 'dob': dobIso8601,
    };
    if (meta.isNotEmpty) {
      await updateAuthMetadata(meta);
    }
  }

  /// Update auth.user metadata
  static Future<void> updateAuthMetadata(Map<String, dynamic> data) async {
    await supabase.auth.updateUser(UserAttributes(data: data));
  }
}
