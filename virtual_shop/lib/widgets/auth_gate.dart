import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:virtual_shop/utils/supabase_service.dart';

class AuthGate extends StatefulWidget {
  final Widget signedIn;
  final Widget signedOut;
  const AuthGate({super.key, required this.signedIn, required this.signedOut});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _supabase = Supabase.instance.client;
  Session? _session;
  bool _initializing = true;
  bool _checkingProfile = false;
  bool _navigatedToComplete = false;
  String? _handledAuthId;

  @override
  void initState() {
    super.initState();
    _session = _supabase.auth.currentSession;
    _initializing = false;
    if (_session != null) {
      _checkAndMaybeRedirect(_session!);
    }
    _supabase.auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      setState(() {
        _session = event.session;
      });
      if (event.session != null) {
        _checkAndMaybeRedirect(event.session!);
      } else {
        // Signed out, reset flags
        _checkingProfile = false;
        _navigatedToComplete = false;
        _handledAuthId = null;
      }
    });
  }

  Future<void> _checkAndMaybeRedirect(Session session) async {
    if (_navigatedToComplete) return;
    if (_checkingProfile) return;
    final email = session.user.email;
    final userId = session.user.id;
    if (_handledAuthId != null && _handledAuthId == userId) return;
    if (email == null || email.isEmpty) return;
    setState(() => _checkingProfile = true);
    try {
      // Ensure a users row exists
      await SupabaseService.upsertUserProfile(id: userId, email: email);
      final complete = await SupabaseService.isProfileComplete(email);
      if (!complete && mounted && !_navigatedToComplete) {
        _navigatedToComplete = true;
        Navigator.pushReplacementNamed(
          context,
          '/complete_profile',
          arguments: {'email': email},
        );
        return;
      }
    } catch (_) {
      // If check fails, don't block entry to the app
    } finally {
      _handledAuthId = userId;
      if (mounted) setState(() => _checkingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing || _checkingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _session == null ? widget.signedOut : widget.signedIn;
  }
}
