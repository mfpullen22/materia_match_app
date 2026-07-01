import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:forui/forui.dart";

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  var _enteredEmail = "";
  var _enteredPassword = "";
  var _isAuthenticating = false;
  var _isLogin = true;
  var _obscurePassword = true;
  var _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final isValid = _form.currentState!.validate();
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    _form.currentState!.save();

    setState(() => _isAuthenticating = true);

    try {
      if (_isLogin) {
        await _firebase.signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
      } else {
        await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
      }
    } on FirebaseAuthException catch (e) {
      var message = "Authentication failed. Please try again.";

      if (e.code == "email-already-in-use") {
        message = "This email is already registered.";
      } else if (e.code == "invalid-email") {
        message = "Please enter a valid email address.";
      } else if (e.code == "wrong-password" || e.code == "invalid-credential") {
        message = "Incorrect email or password.";
      } else if (e.code == "user-not-found") {
        message = "No account found for this email.";
      } else if (e.code == "weak-password") {
        message = "Password is too weak.";
      }

      _showMessage(message);
    } catch (_) {
      _showMessage("Something went wrong. Please try again.");
    }

    if (mounted) {
      setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains("@")) {
      _showMessage("Enter your email address first.");
      return;
    }

    try {
      await _firebase.sendPasswordResetEmail(email: email);
      _showMessage("Password reset email sent.");
    } on FirebaseAuthException catch (e) {
      var message = "Could not send password reset email.";

      if (e.code == "invalid-email") {
        message = "Please enter a valid email address.";
      } else if (e.code == "user-not-found") {
        message = "No account found for this email.";
      }

      _showMessage(message);
    } catch (_) {
      _showMessage("Could not send password reset email.");
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _confirmPasswordController.clear();
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surface.withValues(alpha: 0.72),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.24),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.24),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.20),
              colorScheme.surface,
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      "assets/img/logo_bgless.png",
                      height: (screenSize.height * 0.32).clamp(190.0, 290.0),
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin
                          ? "Sign in to view team reports and prepare for your next match."
                          : "Create an account to start building and sharing team match data.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.14),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isLogin ? "Welcome back" : "Create your account",
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isLogin
                                  ? "Enter your details below to continue."
                                  : "Use an email and password to get started.",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.64,
                                    ),
                                  ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              decoration: _inputDecoration(
                                context: context,
                                label: "Email address",
                                icon: Icons.email_outlined,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                final email = value?.trim() ?? "";

                                if (email.isEmpty || !email.contains("@")) {
                                  return "Enter a valid email.";
                                }

                                return null;
                              },
                              onSaved: (value) => _enteredEmail = value!.trim(),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              decoration: _inputDecoration(
                                context: context,
                                label: "Password",
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              obscureText: _obscurePassword,
                              textInputAction: _isLogin
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return "Password must be at least 6 characters.";
                                }

                                return null;
                              },
                              onSaved: (value) => _enteredPassword = value!,
                              onFieldSubmitted: (_) {
                                if (_isLogin) _submit();
                              },
                            ),
                            if (!_isLogin) ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: _inputDecoration(
                                  context: context,
                                  label: "Confirm password",
                                  icon: Icons.lock_reset_outlined,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return "Passwords do not match.";
                                  }

                                  return null;
                                },
                                onFieldSubmitted: (_) => _submit(),
                              ),
                            ],
                            if (_isLogin) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _resetPassword,
                                  child: const Text("Forgot password?"),
                                ),
                              ),
                            ] else
                              const SizedBox(height: 20),
                            if (_isAuthenticating)
                              const Center(child: CircularProgressIndicator())
                            else
                              SizedBox(
                                height: 52,
                                child: FButton(
                                  onPress: _submit,
                                  child: Text(
                                    _isLogin ? "Sign In" : "Create Account",
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _isAuthenticating ? null : _toggleMode,
                              child: Text(
                                _isLogin
                                    ? "New to Materia Match? Create an account"
                                    : "Already have an account? Sign in",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "Share scouting notes. Track matchups. Help your team prepare.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
