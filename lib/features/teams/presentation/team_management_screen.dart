import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:forui/forui.dart";
import "package:materia_match_app/features/teams/data/team_repository.dart";
import "package:materia_match_app/features/teams/domain/team.dart";
import "package:materia_match_app/features/teams/presentation/create_team_screen.dart";
import "package:materia_match_app/features/teams/presentation/switch_active_team_screen.dart";
import "package:materia_match_app/features/teams/presentation/team_management_controller.dart";

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamCodeController = TextEditingController();

  late final TeamManagementController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TeamManagementController(repository: TeamRepository());
  }

  @override
  void dispose() {
    _teamCodeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _joinTeam() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final message = await _controller.joinTeam(_teamCodeController.text);

    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    if (message != null) {
      _teamCodeController.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      return;
    }

    final error = _controller.errorMessage ?? "Unable to join team.";

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  void _openCreateTeamScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateTeamScreen()));
  }

  void _openSwitchActiveTeamScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SwitchActiveTeamScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Team Management")),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isShortScreen = constraints.maxHeight < 600;

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    isShortScreen ? 12 : 18,
                    18,
                    18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTeamStatusCard(context, _controller.data),
                      SizedBox(height: isShortScreen ? 12 : 16),
                      _buildJoinTeamSection(context),
                      const Spacer(),
                      _buildBottomActions(context),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTeamStatusCard(BuildContext context, TeamManagementData data) {
    final activeTeam = data.activeTeam;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: _controller.isLoading
            ? const SizedBox(
                height: 56,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activeTeam != null
                        ? "Current Active Team"
                        : data.hasTeams
                        ? "No Active Team Selected"
                        : "No Team Yet",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _statusTitle(data),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (data.hasTeams) ...[
                    const SizedBox(height: 4),
                    Text(
                      "${data.teams.length} team${data.teams.length == 1 ? "" : "s"} joined",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (activeTeam != null) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      "Invite others to your team using this code:",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    _buildInviteCodeRow(context, activeTeam),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildInviteCodeRow(BuildContext context, TeamSummary activeTeam) {
    final code = activeTeam.joinCode.trim();

    if (code.isEmpty) {
      return Text(
        "No invite code available.",
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.45),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              code,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Team code copied.")),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text("Copy"),
          ),
        ],
      ),
    );
  }

  String _statusTitle(TeamManagementData data) {
    final activeTeam = data.activeTeam;

    if (activeTeam != null) {
      return activeTeam.name;
    }

    if (data.hasTeams) {
      return "Choose an active team";
    }

    return "You aren’t part of a team yet.";
  }

  Widget _buildJoinTeamSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Join a Team",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _teamCodeController,
                decoration: const InputDecoration(
                  labelText: "Team Code",
                  hintText: "Example: ABC123",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter a team code.";
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: _controller.isJoining
                    ? const Center(child: CircularProgressIndicator())
                    : FButton(
                        onPress: _joinTeam,
                        child: const Text("Join Team"),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 50,
          child: FButton(
            onPress: _openCreateTeamScreen,
            child: const Text("Create Team"),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: FButton(
            onPress: _openSwitchActiveTeamScreen,
            child: const Text("Switch Active Team"),
          ),
        ),
      ],
    );
  }
}
