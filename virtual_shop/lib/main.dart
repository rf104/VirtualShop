import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:virtual_shop/pages/home_page.dart';
import 'package:virtual_shop/pages/landing_page.dart';
import 'package:virtual_shop/utils/theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const LandingPage(),
    );
  }
}
