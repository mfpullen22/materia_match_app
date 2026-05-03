import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:forui/forui.dart";

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  var _enteredEmail = "";
  var _enteredPassword = "";
  var _isAuthenticating = false;
  var _isLogin = false; // 🔥 toggle mode

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submit() async {
    final isValid = _form.currentState!.validate();
    if (!isValid) return;

    _form.currentState!.save();

    setState(() => _isAuthenticating = true);

    try {
      if (_isLogin) {
        // 🔑 LOGIN
        await _firebase.signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
      } else {
        // 🆕 SIGN UP
        await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Authentication failed.";

      if (e.code == "email-already-in-use") {
        message = "This email is already registered.";
      } else if (e.code == "invalid-email") {
        message = "Invalid email address.";
      } else if (e.code == "wrong-password") {
        message = "Incorrect password.";
      } else if (e.code == "user-not-found") {
        message = "No account found for this email.";
      } else if (e.code == "weak-password") {
        message = "Password is too weak.";
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    if (mounted) {
      setState(() => _isAuthenticating = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(20),
                width: 350,
                child: Image.asset("assets/img/logo_bgless.png"),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: "Email Address",
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty ||
                                !value.contains("@")) {
                              return "Enter a valid email.";
                            }
                            return null;
                          },
                          onSaved: (value) => _enteredEmail = value!,
                        ),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: "Password",
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return "Min 6 characters.";
                            }
                            return null;
                          },
                          onSaved: (value) => _enteredPassword = value!,
                        ),
                        const SizedBox(height: 12),

                        if (_isAuthenticating)
                          const CircularProgressIndicator()
                        else ...[
                          FButton(
                            onPress: _submit,
                            child: Text(
                              _isLogin ? "Sign In" : "Create Account",
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _toggleMode,
                            child: Text(
                              _isLogin
                                  ? "Create an Account"
                                  : "I already have an account",
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
