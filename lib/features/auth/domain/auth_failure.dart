enum AuthFailureCode {
  emailAlreadyInUse,
  invalidEmail,
  wrongPassword,
  userNotFound,
  weakPassword,
  userDisabled,
  invalidTeamCode,
  permissionDenied,
  emailLookupFailed,
  userCreationFailed,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  final AuthFailureCode code;
  final String message;

  bool get isInvalidTeamCode => code == AuthFailureCode.invalidTeamCode;

  bool get isEmailAlreadyInUse => code == AuthFailureCode.emailAlreadyInUse;
}
