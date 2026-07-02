class SignupRequest {
  const SignupRequest({
    required this.firstName,
    required this.lastNameOrInitial,
    required this.email,
    required this.password,
    required this.teamCode,
  });

  final String firstName;
  final String lastNameOrInitial;
  final String email;
  final String password;
  final String teamCode;

  String get trimmedFirstName => firstName.trim();
  String get trimmedLastNameOrInitial => lastNameOrInitial.trim();
  String get trimmedEmail => email.trim();
  String get normalizedEmail => email.trim().toLowerCase();
  String get normalizedTeamCode => teamCode.trim().toUpperCase();

  String get displayName => "$trimmedFirstName $trimmedLastNameOrInitial";
}
