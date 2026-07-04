import "package:flutter/material.dart";

class CreateTeamScreen extends StatelessWidget {
  const CreateTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Team")),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Create Team screen will be built next.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
