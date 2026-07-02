import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:forui/forui.dart";

final _firebase = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginForm = GlobalKey<FormState>();
  final _nameForm = GlobalKey<FormState>();
  final _accountForm = GlobalKey<FormState>();
  final _teamForm = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _firstNameController = TextEditingController();
  final _lastNameOrInitialController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _teamCodeController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  var _isLogin = true;
  var _isAuthenticating = false;
  var _currentSignupStep = 0;

  String? _teamCodeError;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameOrInitialController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _teamCodeController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  String _emailLookupId(String email) {
    return Uri.encodeComponent(email.trim().toLowerCase());
  }

  Future<bool> _emailAlreadyHasAccount(String email) async {
    final emailId = _emailLookupId(email);

    final emailDoc = await _firestore
        .collection("userEmails")
        .doc(emailId)
        .get();

    return emailDoc.exists;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _isAuthenticating = false;
      _currentSignupStep = 0;
      _teamCodeError = null;
    });
  }

  void _goToSignupStep(int step) {
    setState(() {
      _currentSignupStep = step.clamp(0, 2);
      _teamCodeError = null;
    });
  }

  Future<void> _nextSignupStep() async {
    if (_currentSignupStep == 0) {
      final isValid = _nameForm.currentState!.validate();

      if (!isValid) return;

      _goToSignupStep(1);
      return;
    }

    if (_currentSignupStep == 1) {
      final isValid = _accountForm.currentState!.validate();

      if (!isValid) return;

      if (_isAuthenticating) return;

      setState(() => _isAuthenticating = true);

      try {
        final emailAlreadyExists = await _emailAlreadyHasAccount(
          _signupEmailController.text,
        );

        if (emailAlreadyExists) {
          _showMessage(
            "An account already exists with this email address. "
            "Please sign in instead.",
          );

          return;
        }

        _goToSignupStep(2);
      } on FirebaseException catch (e) {
        var message =
            "Unable to check whether this email is already registered.";

        if (e.code == "permission-denied") {
          message =
              "The app does not currently have permission to check existing accounts. "
              "Please update your Firestore rules.";
        }

        _showMessage(message);
      } catch (_) {
        _showMessage("Unable to check this email address. Please try again.");
      } finally {
        if (mounted) {
          setState(() => _isAuthenticating = false);
        }
      }
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findTeamByCode(
    String teamCode,
  ) async {
    final normalizedCode = teamCode.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      return null;
    }

    final matchingTeams = await _firestore
        .collection("teams")
        .where("teamCode", isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (matchingTeams.docs.isEmpty) {
      return null;
    }

    return matchingTeams.docs.first;
  }

  Future<void> _submitLogin() async {
    final isValid = _loginForm.currentState!.validate();

    if (!isValid) return;

    if (_isAuthenticating) return;

    setState(() => _isAuthenticating = true);

    try {
      await _firebase.signInWithEmailAndPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(_friendlyAuthError(e));
    } catch (_) {
      _showMessage("Something went wrong. Please try again.");
    }

    if (mounted) {
      setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _submitSignup() async {
    final teamIsValid = _teamForm.currentState?.validate() ?? false;

    if (!teamIsValid) {
      return;
    }

    if (_firstNameController.text.trim().isEmpty ||
        _lastNameOrInitialController.text.trim().isEmpty) {
      _goToSignupStep(0);
      return;
    }

    if (_signupEmailController.text.trim().isEmpty ||
        !_signupEmailController.text.trim().contains("@") ||
        _signupPasswordController.text.length < 6 ||
        _signupPasswordController.text !=
            _signupConfirmPasswordController.text) {
      _goToSignupStep(1);
      return;
    }

    final emailAlreadyExists = await _emailAlreadyHasAccount(
      _signupEmailController.text,
    );

    if (emailAlreadyExists) {
      _goToSignupStep(1);

      _showMessage(
        "An account already exists with this email address. "
        "Please sign in instead.",
      );

      return;
    }

    if (_isAuthenticating) return;

    setState(() => _isAuthenticating = true);

    try {
      final normalizedTeamCode = _teamCodeController.text.trim().toUpperCase();

      DocumentSnapshot<Map<String, dynamic>>? matchedTeam;

      if (normalizedTeamCode.isNotEmpty) {
        matchedTeam = await _findTeamByCode(normalizedTeamCode);

        if (matchedTeam == null) {
          setState(() {
            _teamCodeError =
                "Invalid team code. Correct it or leave it blank to create an account without a team.";
          });

          _teamForm.currentState?.validate();

          _showMessage(
            "That team code is invalid. Please correct it or leave it blank "
            "to create an account without a team. You can still join a team "
            "after account creation.",
          );

          if (mounted) {
            setState(() => _isAuthenticating = false);
          }

          return;
        }
      }

      final userCredentials = await _firebase.createUserWithEmailAndPassword(
        email: _signupEmailController.text.trim(),
        password: _signupPasswordController.text,
      );

      final user = userCredentials.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: "user-creation-failed",
          message: "The account could not be created.",
        );
      }

      final teamData = matchedTeam?.data();

      final normalizedEmail = _signupEmailController.text.trim().toLowerCase();
      final emailLookupId = _emailLookupId(normalizedEmail);

      final userDocRef = _firestore.collection("users").doc(user.uid);
      final userEmailDocRef = _firestore
          .collection("userEmails")
          .doc(emailLookupId);

      final batch = _firestore.batch();

      batch.set(userDocRef, {
        "uid": user.uid,
        "email": _signupEmailController.text.trim(),
        "firstName": _firstNameController.text.trim(),
        "lastNameOrInitial": _lastNameOrInitialController.text.trim(),
        "displayName":
            "${_firstNameController.text.trim()} ${_lastNameOrInitialController.text.trim()}",
        "teamId": matchedTeam?.id,
        "teamName": teamData?["name"],
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
        "emailLower": normalizedEmail,
      });

      batch.set(userEmailDocRef, {
        "uid": user.uid,
        "emailLower": normalizedEmail,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (matchedTeam != null) {
        batch.update(matchedTeam.reference, {
          "memberIds": FieldValue.arrayUnion([user.uid]),
          "updatedAt": FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } on FirebaseAuthException catch (e) {
      _showMessage(_friendlyAuthError(e));
    } on FirebaseException catch (e) {
      var message = "Something went wrong while creating your account.";

      if (e.code == "permission-denied") {
        message =
            "The app does not currently have permission to check or save team information. "
            "Please update your Firestore rules.";
      }

      _showMessage(message);
    } catch (_) {
      _showMessage("Something went wrong. Please try again.");
    }

    if (mounted) {
      setState(() => _isAuthenticating = false);
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    if (e.code == "email-already-in-use") {
      return "An account already exists with this email address. Please sign in instead.";
    }

    if (e.code == "invalid-email") {
      return "Invalid email address.";
    }

    if (e.code == "wrong-password" || e.code == "invalid-credential") {
      return "Incorrect email or password.";
    }

    if (e.code == "user-not-found") {
      return "No account found for this email.";
    }

    if (e.code == "weak-password") {
      return "Password is too weak.";
    }

    if (e.code == "user-disabled") {
      return "This account has been disabled.";
    }

    if (e.message != null && e.message!.trim().isNotEmpty) {
      return e.message!;
    }

    return "Authentication failed.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 320,
                    child: Image.asset("assets/img/logo_bgless.png"),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _isLogin
                            ? _buildLoginContent()
                            : _buildSignupContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginContent() {
    return Form(
      key: _loginForm,
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
            controller: _loginEmailController,
            decoration: const InputDecoration(labelText: "Email Address"),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _loginPasswordController,
            decoration: const InputDecoration(labelText: "Password"),
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: _validatePassword,
            onFieldSubmitted: (_) => _submitLogin(),
          ),
          const SizedBox(height: 20),
          if (_isAuthenticating)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(
              width: double.infinity,
              child: FButton(
                onPress: _submitLogin,
                child: const Text("Sign In"),
              ),
            ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _isAuthenticating ? null : _toggleMode,
            child: const Text("Create an Account"),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupContent() {
    return Column(
      key: const ValueKey("signup"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
          _signupStepSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        LinearProgressIndicator(value: (_currentSignupStep + 1) / 3),
        const SizedBox(height: 8),
        Text(
          "Step ${_currentSignupStep + 1} of 3",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
          child: _buildCurrentSignupStep(),
        ),
        const SizedBox(height: 20),
        _buildSignupNavigation(),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _isAuthenticating ? null : _toggleMode,
          child: const Text("I already have an account"),
        ),
      ],
    );
  }

  String get _signupStepSubtitle {
    if (_currentSignupStep == 0) {
      return "Tell us who you are.";
    }

    if (_currentSignupStep == 1) {
      return "Set up your login details.";
    }

    return "Join a team now, or skip this step.";
  }

  Widget _buildCurrentSignupStep() {
    if (_currentSignupStep == 0) {
      return _buildNameStep();
    }

    if (_currentSignupStep == 1) {
      return _buildAccountStep();
    }

    return _buildTeamStep();
  }

  Widget _buildNameStep() {
    return Form(
      key: _nameForm,
      child: Column(
        key: const ValueKey("name-step"),
        children: [
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(labelText: "First Name"),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Enter your first name.";
              }

              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _lastNameOrInitialController,
            decoration: const InputDecoration(
              labelText: "Last Name or Initial",
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Enter your last name or initial.";
              }

              return null;
            },
            onFieldSubmitted: (_) => _nextSignupStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStep() {
    return Form(
      key: _accountForm,
      child: Column(
        key: const ValueKey("account-step"),
        children: [
          TextFormField(
            controller: _signupEmailController,
            decoration: const InputDecoration(labelText: "Email Address"),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _signupPasswordController,
            decoration: const InputDecoration(labelText: "Password"),
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: _validatePassword,
            onChanged: (_) {
              if (_signupConfirmPasswordController.text.isNotEmpty) {
                _accountForm.currentState?.validate();
              }
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _signupConfirmPasswordController,
            decoration: const InputDecoration(labelText: "Re-enter Password"),
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: _validateConfirmPassword,
            onFieldSubmitted: (_) => _nextSignupStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStep() {
    return Form(
      key: _teamForm,
      child: Column(
        key: const ValueKey("team-step"),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _teamCodeController,
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

              return _teamCodeError;
            },
            onChanged: (_) {
              if (_teamCodeError != null) {
                setState(() => _teamCodeError = null);
              }
            },
            onFieldSubmitted: (_) => _submitSignup(),
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

  Widget _buildSignupNavigation() {
    if (_isAuthenticating) {
      return const Center(child: CircularProgressIndicator());
    }

    final isFirstStep = _currentSignupStep == 0;
    final isFinalStep = _currentSignupStep == 2;

    return Row(
      children: [
        if (!isFirstStep)
          Expanded(
            child: OutlinedButton(
              onPressed: () => _goToSignupStep(_currentSignupStep - 1),
              child: const Text("Back"),
            ),
          ),
        if (!isFirstStep) const SizedBox(width: 12),
        Expanded(
          child: FButton(
            onPress: isFinalStep ? _submitSignup : _nextSignupStep,
            child: Text(isFinalStep ? "Create Account" : "Next"),
          ),
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? "";

    if (email.isEmpty || !email.contains("@")) {
      return "Enter a valid email.";
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return "Min 6 characters.";
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Re-enter your password.";
    }

    if (value != _signupPasswordController.text) {
      return "Passwords do not match.";
    }

    return null;
  }
}
