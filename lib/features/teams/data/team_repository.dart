import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:materia_match_app/features/teams/domain/team.dart";

class TeamRepositoryException implements Exception {
  const TeamRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InvalidTeamCodeException extends TeamRepositoryException {
  const InvalidTeamCodeException() : super("That team code is invalid.");
}

class TeamRepository {
  TeamRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  User _requireUser() {
    final user = _auth.currentUser;

    if (user == null) {
      throw const TeamRepositoryException("You must be signed in.");
    }

    return user;
  }

  Stream<TeamManagementData> watchTeamManagementData() {
    final user = _requireUser();

    return _firestore.collection("users").doc(user.uid).snapshots().asyncMap((
      snapshot,
    ) async {
      final data = snapshot.data();

      final teamIds = _readStringList(data?["teamIds"]);
      final activeTeamId = _readOptionalString(data?["activeTeamId"]);

      if (teamIds.isEmpty) {
        return TeamManagementData(teams: const [], activeTeamId: activeTeamId);
      }

      final teamDocs = await Future.wait(
        teamIds.map(
          (teamId) => _firestore.collection("teams").doc(teamId).get(),
        ),
      );

      final teams =
          teamDocs
              .where((doc) => doc.exists)
              .map(TeamSummary.fromSnapshot)
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      return TeamManagementData(teams: teams, activeTeamId: activeTeamId);
    });
  }

  Future<JoinTeamResult> joinTeamByCode(String rawCode) async {
    final user = _requireUser();
    final normalizedCode = normalizeTeamCode(rawCode);

    if (normalizedCode.isEmpty) {
      throw const TeamRepositoryException("Enter a team code.");
    }

    final codeRef = _firestore.collection("teamCodes").doc(normalizedCode);
    final userRef = _firestore.collection("users").doc(user.uid);

    return _firestore.runTransaction((transaction) async {
      final codeDoc = await transaction.get(codeRef);

      if (!codeDoc.exists) {
        throw const InvalidTeamCodeException();
      }

      final codeData = codeDoc.data() ?? <String, dynamic>{};

      final isActiveCode = codeData["active"] != false;
      final teamId = _readOptionalString(codeData["teamId"]);
      final teamName = _readOptionalString(codeData["teamName"]) ?? "Team";

      if (!isActiveCode || teamId == null || teamId.isEmpty) {
        throw const InvalidTeamCodeException();
      }

      final teamRef = _firestore.collection("teams").doc(teamId);
      final teamDoc = await transaction.get(teamRef);

      if (!teamDoc.exists) {
        throw const TeamRepositoryException(
          "This team code points to a team that does not exist.",
        );
      }

      final userDoc = await transaction.get(userRef);
      final userData = userDoc.data() ?? <String, dynamic>{};

      final currentTeamIds = _readStringList(userData["teamIds"]);
      final alreadyMember = currentTeamIds.contains(teamId);

      final currentActiveTeamId = _readOptionalString(userData["activeTeamId"]);
      final shouldBecomeActive =
          currentActiveTeamId == null || currentActiveTeamId.isEmpty;

      final nextTeamIds = alreadyMember
          ? currentTeamIds
          : <String>[...currentTeamIds, teamId];

      final userUpdate = <String, dynamic>{
        "teamIds": nextTeamIds,
        "updatedAt": FieldValue.serverTimestamp(),
      };

      if (!userDoc.exists) {
        userUpdate["createdAt"] = FieldValue.serverTimestamp();

        if (user.email != null) {
          userUpdate["email"] = user.email;
        }
      }

      if (shouldBecomeActive) {
        userUpdate["activeTeamId"] = teamId;
      }

      transaction.set(userRef, userUpdate, SetOptions(merge: true));

      if (!alreadyMember) {
        final teamRef = _firestore.collection("teams").doc(teamId);

        transaction.update(teamRef, {
          "memberIds": FieldValue.arrayUnion([user.uid]),
          "memberCount": FieldValue.increment(1),
          "updatedAt": FieldValue.serverTimestamp(),
        });
      }

      return JoinTeamResult(
        team: TeamSummary(id: teamId, name: teamName, joinCode: normalizedCode),
        alreadyMember: alreadyMember,
        becameActive: shouldBecomeActive,
      );
    });
  }

  Future<void> setActiveTeam(String teamId) async {
    final user = _requireUser();
    final userRef = _firestore.collection("users").doc(user.uid);
    final userDoc = await userRef.get();

    final userData = userDoc.data() ?? <String, dynamic>{};
    final teamIds = _readStringList(userData["teamIds"]);

    if (!teamIds.contains(teamId)) {
      throw const TeamRepositoryException(
        "You can only switch to a team you have joined.",
      );
    }

    await userRef.update({
      "activeTeamId": teamId,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  static String normalizeTeamCode(String rawCode) {
    return rawCode.trim().toUpperCase().replaceAll(RegExp(r"\s+"), "");
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];

    final result = <String>[];
    final seen = <String>{};

    for (final item in value) {
      if (item is! String) continue;

      final cleaned = item.trim();
      if (cleaned.isEmpty) continue;

      if (seen.add(cleaned)) {
        result.add(cleaned);
      }
    }

    return result;
  }

  static String? _readOptionalString(dynamic value) {
    if (value is! String) return null;

    final cleaned = value.trim();
    return cleaned.isEmpty ? null : cleaned;
  }
}
