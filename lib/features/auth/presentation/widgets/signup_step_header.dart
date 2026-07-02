import "package:flutter/material.dart";
import "package:materia_match_app/features/auth/presentation/auth_controller.dart";

class SignupStepHeader extends StatelessWidget {
  const SignupStepHeader({required this.controller, super.key});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Create Account",
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          controller.signupStepSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        LinearProgressIndicator(value: (controller.currentSignupStep + 1) / 3),
        const SizedBox(height: 8),
        Text(
          "Step ${controller.currentSignupStep + 1} of 3",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
