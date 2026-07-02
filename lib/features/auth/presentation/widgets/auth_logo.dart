import "package:flutter/material.dart";

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Image.asset("assets/img/logo_bgless.png"),
    );
  }
}
