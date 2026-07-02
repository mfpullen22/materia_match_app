import "package:flutter/material.dart";
import "package:materia_match_app/features/auth/presentation/auth_controller.dart";
import "package:materia_match_app/features/auth/presentation/widgets/signup_account_step.dart";
import "package:materia_match_app/features/auth/presentation/widgets/signup_name_step.dart";
import "package:materia_match_app/features/auth/presentation/widgets/signup_navigation.dart";
import "package:materia_match_app/features/auth/presentation/widgets/signup_step_header.dart";
import "package:materia_match_app/features/auth/presentation/widgets/signup_team_step.dart";

class SignupFlow extends StatelessWidget {
  const SignupFlow({
    required this.controller,
    required this.onMessage,
    super.key,
  });

  final AuthController controller;
  final AuthMessageHandler onMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey("signup"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SignupStepHeader(controller: controller),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(animation);

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offsetAnimation, child: child),
            );
          },
          child: _buildCurrentStep(),
        ),
        const SizedBox(height: 20),
        SignupNavigation(controller: controller, onMessage: onMessage),
        const SizedBox(height: 10),
        TextButton(
          onPressed: controller.isAuthenticating ? null : controller.toggleMode,
          child: const Text("I already have an account"),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    if (controller.currentSignupStep == 0) {
      return SignupNameStep(controller: controller, onMessage: onMessage);
    }

    if (controller.currentSignupStep == 1) {
      return SignupAccountStep(controller: controller, onMessage: onMessage);
    }

    return SignupTeamStep(controller: controller, onMessage: onMessage);
  }
}
