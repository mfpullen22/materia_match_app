import "package:flutter/material.dart";
import "package:materia_match_app/features/auth/data/auth_repository.dart";
import "package:materia_match_app/features/auth/domain/auth_failure.dart";
import "package:materia_match_app/features/auth/domain/signup_request.dart";

typedef AuthMessageHandler = void Function(String message);

class AuthController extends ChangeNotifier {
  AuthController({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  final loginForm = GlobalKey<FormState>();
  final nameForm = GlobalKey<FormState>();
  final accountForm = GlobalKey<FormState>();
  final teamForm = GlobalKey<FormState>();

  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  final firstNameController = TextEditingController();
  final lastNameOrInitialController = TextEditingController();
  final signupEmailController = TextEditingController();
  final signupPasswordController = TextEditingController();
  final signupConfirmPasswordController = TextEditingController();
  final teamCodeController = TextEditingController();

  bool _isLogin = true;
  bool _isAuthenticating = false;
  int _currentSignupStep = 0;
  String? _teamCodeError;
  bool _isDisposed = false;

  bool get isLogin => _isLogin;
  bool get isAuthenticating => _isAuthenticating;
  int get currentSignupStep => _currentSignupStep;
  String? get teamCodeError => _teamCodeError;

  bool get isFirstSignupStep => _currentSignupStep == 0;
  bool get isFinalSignupStep => _currentSignupStep == 2;

  String get signupStepSubtitle {
    if (_currentSignupStep == 0) {
      return "Tell us who you are.";
    }

    if (_currentSignupStep == 1) {
      return "Set up your login details.";
    }

    return "Join a team now, or skip this step.";
  }

  void toggleMode() {
    _isLogin = !_isLogin;
    _isAuthenticating = false;
    _currentSignupStep = 0;
    _teamCodeError = null;
    _notify();
  }

  void goToSignupStep(int step) {
    int clampedStep = step;

    if (clampedStep < 0) {
      clampedStep = 0;
    }

    if (clampedStep > 2) {
      clampedStep = 2;
    }

    _currentSignupStep = clampedStep;
    _teamCodeError = null;
    _notify();
  }

  void clearTeamCodeError() {
    if (_teamCodeError == null) return;

    _teamCodeError = null;
    _notify();
  }

  Future<void> nextSignupStep({required AuthMessageHandler onMessage}) async {
    if (_currentSignupStep == 0) {
      final isValid = nameForm.currentState?.validate() ?? false;

      if (!isValid) return;

      goToSignupStep(1);
      return;
    }

    if (_currentSignupStep == 1) {
      final isValid = accountForm.currentState?.validate() ?? false;

      if (!isValid) return;
      if (_isAuthenticating) return;

      _setAuthenticating(true);

      try {
        final emailAlreadyExists = await _authRepository.emailAlreadyHasAccount(
          signupEmailController.text,
        );

        if (emailAlreadyExists) {
          onMessage(
            "An account already exists with this email address. Please sign in instead.",
          );

          return;
        }

        goToSignupStep(2);
      } on AuthFailure catch (e) {
        onMessage(e.message);
      } finally {
        _setAuthenticating(false);
      }
    }
  }

  Future<void> submitLogin({required AuthMessageHandler onMessage}) async {
    final isValid = loginForm.currentState?.validate() ?? false;

    if (!isValid) return;
    if (_isAuthenticating) return;

    _setAuthenticating(true);

    try {
      await _authRepository.signIn(
        email: loginEmailController.text,
        password: loginPasswordController.text,
      );
    } on AuthFailure catch (e) {
      onMessage(e.message);
    } finally {
      _setAuthenticating(false);
    }
  }

  Future<void> submitSignup({required AuthMessageHandler onMessage}) async {
    final teamIsValid = teamForm.currentState?.validate() ?? false;

    if (!teamIsValid) return;

    if (!_previousSignupStepsStillValid()) {
      return;
    }

    if (_isAuthenticating) return;

    _setAuthenticating(true);

    final signupRequest = SignupRequest(
      firstName: firstNameController.text,
      lastNameOrInitial: lastNameOrInitialController.text,
      email: signupEmailController.text,
      password: signupPasswordController.text,
      teamCode: teamCodeController.text,
    );

    try {
      await _authRepository.createAccount(signupRequest);
    } on AuthFailure catch (e) {
      if (e.isInvalidTeamCode) {
        _teamCodeError =
            "Invalid team code. Correct it or leave it blank to create an account without a team.";
        _notify();
        teamForm.currentState?.validate();
      }

      if (e.isEmailAlreadyInUse) {
        goToSignupStep(1);
      }

      onMessage(e.message);
    } finally {
      _setAuthenticating(false);
    }
  }

  bool _previousSignupStepsStillValid() {
    if (firstNameController.text.trim().isEmpty ||
        lastNameOrInitialController.text.trim().isEmpty) {
      goToSignupStep(0);
      return false;
    }

    if (signupEmailController.text.trim().isEmpty ||
        !signupEmailController.text.trim().contains("@") ||
        signupPasswordController.text.length < 6 ||
        signupPasswordController.text != signupConfirmPasswordController.text) {
      goToSignupStep(1);
      return false;
    }

    return true;
  }

  void _setAuthenticating(bool value) {
    if (_isDisposed) return;

    _isAuthenticating = value;
    _notify();
  }

  void _notify() {
    if (_isDisposed) return;

    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;

    loginEmailController.dispose();
    loginPasswordController.dispose();

    firstNameController.dispose();
    lastNameOrInitialController.dispose();
    signupEmailController.dispose();
    signupPasswordController.dispose();
    signupConfirmPasswordController.dispose();
    teamCodeController.dispose();

    super.dispose();
  }
}
