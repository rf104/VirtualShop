import 'package:flutter/material.dart';

void main() {
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

        home : Scaffold(
          
          appBar: AppBar(
          title: Text('Virtual Shop'),
          centerTitle: true,
          ),

          bottomNavigationBar: NavigationBar(destinations: [
            NavigationDestination(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            NavigationDestination(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ])
        
        )
    );
  }
}