import "dart:async";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/foundation.dart";
import "package:materia_match_app/features/teams/data/team_repository.dart";
import "package:materia_match_app/features/teams/domain/team.dart";

class TeamManagementController extends ChangeNotifier {
  TeamManagementController({required TeamRepository repository})
    : _repository = repository {
    _watchTeamData();
  }

  final TeamRepository _repository;

  StreamSubscription<TeamManagementData>? _subscription;

  TeamManagementData data = const TeamManagementData(
    teams: [],
    activeTeamId: null,
  );

  bool isLoading = true;
  bool isJoining = false;
  String? errorMessage;

  Future<String?> joinTeam(String code) async {
    isJoining = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.joinTeamByCode(code);

      if (result.alreadyMember) {
        return "You are already a member of ${result.team.name}.";
      }

      if (result.becameActive) {
        return "You joined ${result.team.name}. This is now your active team.";
      }

      return "You joined ${result.team.name}. Use Switch Active Team to make it active.";
    } catch (error) {
      errorMessage = _messageFromError(error);
      return null;
    } finally {
      isJoining = false;
      notifyListeners();
    }
  }

  void _watchTeamData() {
    _subscription = _repository.watchTeamManagementData().listen(
      (incomingData) {
        data = incomingData;
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        isLoading = false;
        errorMessage = _messageFromError(error);
        notifyListeners();
      },
    );
  }

  String _messageFromError(Object error) {
    debugPrint("Team management error: $error");

    if (error is TeamRepositoryException) {
      return error.message;
    }

    if (error is FirebaseException) {
      if (error.code == "permission-denied") {
        return "You do not have permission to join this team. Check your Firestore rules.";
      }

      if (error.code == "not-found") {
        return "This team code points to a team that does not exist.";
      }

      if (error.code == "unavailable") {
        return "Firestore is temporarily unavailable. Please try again.";
      }

      return "Firebase error: ${error.code}";
    }

    return "Something went wrong. Please try again.";
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
