import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:forui/forui.dart";
import "package:materia_match_app/features/teams/presentation/team_management_screen.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final actions = [
      _HomeAction(
        title: "View Event Data",
        icon: Icons.bar_chart_rounded,
        onTap: () {},
      ),
      _HomeAction(
        title: "Team Reports",
        icon: Icons.groups_rounded,
        onTap: () {},
      ),
      _HomeAction(
        title: "Join or Create Team",
        icon: Icons.group_add_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TeamManagementScreen()),
          );
        },
      ),
      _HomeAction(
        title: "My Profile",
        icon: Icons.person_rounded,
        onTap: () {},
      ),
    ];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.16),
              colorScheme.surface,
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight = constraints.maxHeight;
              final compact = maxHeight < 720;
              final tiny = maxHeight < 640;

              final horizontalPadding = compact ? 18.0 : 22.0;
              final verticalPadding = tiny ? 10.0 : 14.0;

              final logoHeight = (maxHeight * 0.34)
                  .clamp(tiny ? 155.0 : 190.0, tiny ? 230.0 : 285.0)
                  .toDouble();

              final primaryHeight = (maxHeight * 0.09)
                  .clamp(62.0, 82.0)
                  .toDouble();

              final tileHeight = (maxHeight * 0.082)
                  .clamp(58.0, 76.0)
                  .toDouble();

              final logoutHeight = tiny ? 44.0 : 48.0;
              final rowGap = tiny ? 9.0 : 12.0;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  verticalPadding,
                  horizontalPadding,
                  verticalPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Image.asset(
                            "assets/img/logo_bgless.png",
                            height: logoHeight,
                            fit: BoxFit.contain,
                          ),
                        ),

                        SizedBox(height: tiny ? 6 : 8),

                        const Spacer(),

                        _PrimaryActionButton(
                          title: "Report a Match",
                          icon: Icons.edit_note_rounded,
                          height: primaryHeight,
                          onTap: () {},
                        ),

                        const Spacer(),

                        Text(
                          "Team Tools",
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),

                        SizedBox(height: tiny ? 7 : 9),

                        Row(
                          children: [
                            Expanded(
                              child: _HomeActionButton(
                                action: actions[0],
                                height: tileHeight,
                              ),
                            ),
                            SizedBox(width: rowGap),
                            Expanded(
                              child: _HomeActionButton(
                                action: actions[1],
                                height: tileHeight,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: rowGap),

                        Row(
                          children: [
                            Expanded(
                              child: _HomeActionButton(
                                action: actions[2],
                                height: tileHeight,
                              ),
                            ),
                            SizedBox(width: rowGap),
                            Expanded(
                              child: _HomeActionButton(
                                action: actions[3],
                                height: tileHeight,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        SizedBox(
                          height: logoutHeight,
                          child: FButton(
                            onPress: _logout,
                            child: const Text("Logout"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.title,
    required this.icon,
    required this.height,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.74),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colorScheme.onPrimary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: colorScheme.onPrimary.withValues(alpha: 0.86),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({required this.action, required this.height});

  final _HomeAction action;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: colorScheme.primary, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.05,
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

class _HomeAction {
  const _HomeAction({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
}
