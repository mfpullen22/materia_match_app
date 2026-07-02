import "package:flutter/material.dart";
import "package:materia_match_app/features/auth/presentation/auth_controller.dart";
import "package:materia_match_app/features/auth/presentation/auth_validators.dart";

class SignupNameStep extends StatelessWidget {
  const SignupNameStep({
    required this.controller,
    required this.onMessage,
    super.key,
  });

  final AuthController controller;
  final AuthMessageHandler onMessage;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.nameForm,
      child: Column(
        key: const ValueKey("name-step"),
        children: [
          TextFormField(
            controller: controller.firstNameController,
            decoration: const InputDecoration(labelText: "First Name"),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.requiredFirstName,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: controller.lastNameOrInitialController,
            decoration: const InputDecoration(
              labelText: "Last Name or Initial",
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            validator: AuthValidators.requiredLastNameOrInitial,
            onFieldSubmitted: (_) {
              controller.nextSignupStep(onMessage: onMessage);
            },
          ),
        ],
      ),
    );
  }
}
