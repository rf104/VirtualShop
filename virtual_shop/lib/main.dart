import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:virtual_shop/pages/landing_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       debugShowCheckedModeBanner: false,
       theme: ThemeData(colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal ,
        brightness: Brightness.dark,
        )),

        home : LandingPage(),
        // Scaffold(
          
        //   appBar: AppBar(
        //   title: Text('Virtual Shop'),
        //   centerTitle: true,
        //   actions: [
        //     IconButton(onPressed: (){{}}, icon: Icon(Icons.login_rounded)),
        //   ],
        //   ),

        //   bottomNavigationBar: NavigationBar(destinations: [
        //     NavigationDestination(
        //       icon: Icon(Icons.home),
        //       label: 'Home',
        //     ),
        //     NavigationDestination(
        //       icon: Icon(Icons.shopping_cart),
        //       label: 'Cart',
        //     ),
        //     NavigationDestination(
        //       icon: Icon(Icons.person),
        //       label: 'Profile',
        //     ),
        //   ])
        
        // )
    );
  }
}