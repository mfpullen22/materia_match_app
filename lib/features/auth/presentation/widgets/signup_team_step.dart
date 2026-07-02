import "package:flutter/material.dart";
import "package:materia_match_app/features/auth/presentation/auth_controller.dart";

class SignupTeamStep extends StatelessWidget {
  const SignupTeamStep({
    required this.controller,
    required this.onMessage,
    super.key,
  });

  final AuthController controller;
  final AuthMessageHandler onMessage;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.teamForm,
      child: Column(
        key: const ValueKey("team-step"),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller.teamCodeController,
            decoration: const InputDecoration(
              labelText: "Team Code",
              helperText:
                  "Optional. Leave blank to create an account without a team.",
            ),
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return null;
              }

              return controller.teamCodeError;
            },
            onChanged: (_) {
              controller.clearTeamCodeError();
            },
            onFieldSubmitted: (_) {
              controller.submitSignup(onMessage: onMessage);
            },
          ),
          const SizedBox(height: 12),
          Text(
            "You can still join or create a team later from the home screen.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
