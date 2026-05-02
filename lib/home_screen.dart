import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Image.asset(
            "assets/img/logo_bgless.png",
            height: 360,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
