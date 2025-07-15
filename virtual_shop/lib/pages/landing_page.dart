import 'package:flutter/material.dart';
import 'package:virtual_shop/pages/login.dart';
import 'package:virtual_shop/pages/signup.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title : Text('Virtual Shop!'),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart, size: 50, color: Colors.teal),
                    SizedBox(width: 10),
                    Text(
                      'Virtual Shop',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SvgPicture.asset(
                  'assets/images/4.svg',
                  width: 550,
                  height: 550,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUp()),
                    );
                    // Navigate to login page
                  },

                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                      Colors.teal,
                    ),
                    foregroundColor: WidgetStateProperty.all<Color>(
                      Colors.white,
                    ),
                    minimumSize: WidgetStateProperty.all<Size>(Size(200, 50)),
                  ),
                  child: Text('Getting Started'),
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to login page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Login()),
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                      Colors.teal,
                    ),
                    foregroundColor: WidgetStateProperty.all<Color>(
                      Colors.white,
                    ),
                    minimumSize: WidgetStateProperty.all<Size>(Size(200, 50)),
                  ),
                  child: Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
