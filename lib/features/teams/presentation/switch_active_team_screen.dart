import "package:flutter/material.dart";

class SwitchActiveTeamScreen extends StatelessWidget {
  const SwitchActiveTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Switch Active Team")),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Switch Active Team screen will be built later.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
