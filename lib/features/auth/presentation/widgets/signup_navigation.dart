import "package:flutter/material.dart";
import "package:forui/forui.dart";
import "package:materia_match_app/features/auth/presentation/auth_controller.dart";

class SignupNavigation extends StatelessWidget {
  const SignupNavigation({
    required this.controller,
    required this.onMessage,
    super.key,
  });

  final AuthController controller;
  final AuthMessageHandler onMessage;

  @override
  Widget build(BuildContext context) {
    if (controller.isAuthenticating) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        if (!controller.isFirstSignupStep)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                controller.goToSignupStep(controller.currentSignupStep - 1);
              },
              child: const Text("Back"),
            ),
          ),
        if (!controller.isFirstSignupStep) const SizedBox(width: 12),
        Expanded(
          child: FButton(
            onPress: () {
              if (controller.isFinalSignupStep) {
                controller.submitSignup(onMessage: onMessage);
              } else {
                controller.nextSignupStep(onMessage: onMessage);
              }
            },
            child: Text(
              controller.isFinalSignupStep ? "Create Account" : "Next",
            ),
          ),
        ),
      ],
    );
  }
}
