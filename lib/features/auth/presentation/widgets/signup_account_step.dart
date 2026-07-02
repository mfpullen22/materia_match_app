import "package:flutter/material.dart";
import "package:materia_match_app/features/auth/presentation/auth_controller.dart";
import "package:materia_match_app/features/auth/presentation/auth_validators.dart";

class SignupAccountStep extends StatelessWidget {
  const SignupAccountStep({
    required this.controller,
    required this.onMessage,
    super.key,
  });

  final AuthController controller;
  final AuthMessageHandler onMessage;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.accountForm,
      child: Column(
        key: const ValueKey("account-step"),
        children: [
          TextFormField(
            controller: controller.signupEmailController,
            decoration: const InputDecoration(labelText: "Email Address"),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.email,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: controller.signupPasswordController,
            decoration: const InputDecoration(labelText: "Password"),
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.password,
            onChanged: (_) {
              if (controller.signupConfirmPasswordController.text.isNotEmpty) {
                controller.accountForm.currentState?.validate();
              }
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: controller.signupConfirmPasswordController,
            decoration: const InputDecoration(labelText: "Re-enter Password"),
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (value) => AuthValidators.confirmPassword(
              value: value,
              password: controller.signupPasswordController.text,
            ),
            onFieldSubmitted: (_) {
              controller.nextSignupStep(onMessage: onMessage);
            },
          ),
        ],
      ),
    );
  }
}
