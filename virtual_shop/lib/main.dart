import 'package:flutter/material.dart';
import 'package:virtual_shop/pages/home_page.dart';
import 'package:virtual_shop/pages/landing_page.dart';
import 'package:virtual_shop/utils/expressive_theme.dart';
import 'package:virtual_shop/widgets/auth_gate.dart';
import 'package:virtual_shop/pages/complete_profile_page.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ExpressiveTheme.createLightTheme(),
      darkTheme: ExpressiveTheme.createDarkTheme(),
      themeMode: ThemeMode.system,
      routes: {
        '/complete_profile': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final email = args != null ? args['email'] as String? : null;
          return CompleteProfilePage(email: email ?? '');
        },
      },
      home: const AuthGate(signedIn: HomePage(), signedOut: LandingPage()),
    );
  }
}
