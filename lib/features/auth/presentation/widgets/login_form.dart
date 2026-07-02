import "package:flutter/material.dart";
import "package:forui/forui.dart";
import "package:materia_match_app/features/auth/presentation/auth_controller.dart";
import "package:materia_match_app/features/auth/presentation/auth_validators.dart";

class LoginForm extends StatelessWidget {
  const LoginForm({
    required this.controller,
    required this.onMessage,
    super.key,
  });

  final AuthController controller;
  final AuthMessageHandler onMessage;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.loginForm,
      child: Column(
        key: const ValueKey("login"),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Sign In",
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Welcome back to Materia Match.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: controller.loginEmailController,
            decoration: const InputDecoration(labelText: "Email Address"),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.email,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: controller.loginPasswordController,
            decoration: const InputDecoration(labelText: "Password"),
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: AuthValidators.password,
            onFieldSubmitted: (_) {
              controller.submitLogin(onMessage: onMessage);
            },
          ),
          const SizedBox(height: 20),
          if (controller.isAuthenticating)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(
              width: double.infinity,
              child: FButton(
                onPress: () {
                  controller.submitLogin(onMessage: onMessage);
                },
                child: const Text("Sign In"),
              ),
            ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: controller.isAuthenticating
                ? null
                : controller.toggleMode,
            child: const Text("Create an Account"),
          ),
        ],
      ),
    );
  }
}
