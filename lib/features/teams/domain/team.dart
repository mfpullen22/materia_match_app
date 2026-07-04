import "package:cloud_firestore/cloud_firestore.dart";

class TeamSummary {
  const TeamSummary({
    required this.id,
    required this.name,
    required this.joinCode,
  });

  final String id;
  final String name;
  final String joinCode;

  factory TeamSummary.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    final rawName = data["name"];
    final rawJoinCode = data["joinCode"];

    return TeamSummary(
      id: snapshot.id,
      name: rawName is String && rawName.trim().isNotEmpty
          ? rawName.trim()
          : "Unnamed Team",
      joinCode: rawJoinCode is String ? rawJoinCode.trim() : "",
    );
  }
}

class TeamManagementData {
  const TeamManagementData({required this.teams, required this.activeTeamId});

  final List<TeamSummary> teams;
  final String? activeTeamId;

  bool get hasTeams => teams.isNotEmpty;

  TeamSummary? get activeTeam {
    if (activeTeamId == null || activeTeamId!.isEmpty) return null;

    for (final team in teams) {
      if (team.id == activeTeamId) {
        return team;
      }
    }

    return null;
  }
}

class JoinTeamResult {
  const JoinTeamResult({
    required this.team,
    required this.alreadyMember,
    required this.becameActive,
  });

  final TeamSummary team;
  final bool alreadyMember;
  final bool becameActive;
}
