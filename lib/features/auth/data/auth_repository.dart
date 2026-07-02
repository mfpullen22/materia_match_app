import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:materia_match_app/features/auth/domain/auth_failure.dart";
import "package:materia_match_app/features/auth/domain/signup_request.dart";

class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _authFailureFromFirebaseAuth(e);
    } catch (_) {
      throw const AuthFailure(
        AuthFailureCode.unknown,
        "Something went wrong. Please try again.",
      );
    }
  }

  Future<bool> emailAlreadyHasAccount(String email) async {
    try {
      final emailId = _emailLookupId(email);

      final emailDoc = await _firestore
          .collection("userEmails")
          .doc(emailId)
          .get();

      return emailDoc.exists;
    } on FirebaseException catch (e) {
      if (e.code == "permission-denied") {
        throw const AuthFailure(
          AuthFailureCode.permissionDenied,
          "The app does not currently have permission to check existing accounts. Please update your Firestore rules.",
        );
      }

      throw const AuthFailure(
        AuthFailureCode.emailLookupFailed,
        "Unable to check whether this email is already registered.",
      );
    } catch (_) {
      throw const AuthFailure(
        AuthFailureCode.emailLookupFailed,
        "Unable to check this email address. Please try again.",
      );
    }
  }

  Future<void> createAccount(SignupRequest request) async {
    try {
      final emailAlreadyExists = await emailAlreadyHasAccount(request.email);

      if (emailAlreadyExists) {
        throw const AuthFailure(
          AuthFailureCode.emailAlreadyInUse,
          "An account already exists with this email address. Please sign in instead.",
        );
      }

      final matchedTeam = request.normalizedTeamCode.isEmpty
          ? null
          : await _findTeamByCode(request.normalizedTeamCode);

      if (request.normalizedTeamCode.isNotEmpty && matchedTeam == null) {
        throw const AuthFailure(
          AuthFailureCode.invalidTeamCode,
          "That team code is invalid. Please correct it or leave it blank to create an account without a team. You can still join a team after account creation.",
        );
      }

      final userCredentials = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: request.trimmedEmail,
            password: request.password,
          );

      final user = userCredentials.user;

      if (user == null) {
        throw const AuthFailure(
          AuthFailureCode.userCreationFailed,
          "The account could not be created.",
        );
      }

      await _createUserFirestoreRecords(
        user: user,
        request: request,
        matchedTeam: matchedTeam,
      );
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw _authFailureFromFirebaseAuth(e);
    } on FirebaseException catch (e) {
      if (e.code == "permission-denied") {
        throw const AuthFailure(
          AuthFailureCode.permissionDenied,
          "The app does not currently have permission to check or save account information. Please update your Firestore rules.",
        );
      }

      throw const AuthFailure(
        AuthFailureCode.unknown,
        "Something went wrong while creating your account.",
      );
    } catch (_) {
      throw const AuthFailure(
        AuthFailureCode.unknown,
        "Something went wrong. Please try again.",
      );
    }
  }

  Future<_MatchedTeam?> _findTeamByCode(String normalizedTeamCode) async {
    final matchingTeams = await _firestore
        .collection("teams")
        .where("teamCode", isEqualTo: normalizedTeamCode)
        .limit(1)
        .get();

    if (matchingTeams.docs.isEmpty) {
      return null;
    }

    final doc = matchingTeams.docs.first;
    final data = doc.data();

    return _MatchedTeam(
      id: doc.id,
      name: data["name"] as String?,
      reference: doc.reference,
    );
  }

  Future<void> _createUserFirestoreRecords({
    required User user,
    required SignupRequest request,
    required _MatchedTeam? matchedTeam,
  }) async {
    final emailLookupId = _emailLookupId(request.normalizedEmail);

    final userDocRef = _firestore.collection("users").doc(user.uid);
    final userEmailDocRef = _firestore
        .collection("userEmails")
        .doc(emailLookupId);

    final batch = _firestore.batch();

    batch.set(userDocRef, {
      "uid": user.uid,
      "email": request.trimmedEmail,
      "emailLower": request.normalizedEmail,
      "firstName": request.trimmedFirstName,
      "lastNameOrInitial": request.trimmedLastNameOrInitial,
      "displayName": request.displayName,
      "teamId": matchedTeam?.id,
      "teamName": matchedTeam?.name,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    batch.set(userEmailDocRef, {
      "uid": user.uid,
      "emailLower": request.normalizedEmail,
      "createdAt": FieldValue.serverTimestamp(),
    });

    if (matchedTeam != null) {
      batch.update(matchedTeam.reference, {
        "memberIds": FieldValue.arrayUnion([user.uid]),
        "updatedAt": FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  String _emailLookupId(String email) {
    return Uri.encodeComponent(email.trim().toLowerCase());
  }

  AuthFailure _authFailureFromFirebaseAuth(FirebaseAuthException e) {
    if (e.code == "email-already-in-use") {
      return const AuthFailure(
        AuthFailureCode.emailAlreadyInUse,
        "An account already exists with this email address. Please sign in instead.",
      );
    }

    if (e.code == "invalid-email") {
      return const AuthFailure(
        AuthFailureCode.invalidEmail,
        "Invalid email address.",
      );
    }

    if (e.code == "wrong-password" || e.code == "invalid-credential") {
      return const AuthFailure(
        AuthFailureCode.wrongPassword,
        "Incorrect email or password.",
      );
    }

    if (e.code == "user-not-found") {
      return const AuthFailure(
        AuthFailureCode.userNotFound,
        "No account found for this email.",
      );
    }

    if (e.code == "weak-password") {
      return const AuthFailure(
        AuthFailureCode.weakPassword,
        "Password is too weak.",
      );
    }

    if (e.code == "user-disabled") {
      return const AuthFailure(
        AuthFailureCode.userDisabled,
        "This account has been disabled.",
      );
    }

    return AuthFailure(
      AuthFailureCode.unknown,
      e.message?.trim().isNotEmpty == true
          ? e.message!
          : "Authentication failed.",
    );
  }
}

class _MatchedTeam {
  const _MatchedTeam({
    required this.id,
    required this.name,
    required this.reference,
  });

  final String id;
  final String? name;
  final DocumentReference<Map<String, dynamic>> reference;
}
