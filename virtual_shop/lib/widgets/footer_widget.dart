import 'package:flutter/material.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[800],
      child: Center(
        child: Text(
          '© 2023 Your Company Name. All rights reserved.',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}
