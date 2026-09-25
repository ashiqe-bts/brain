import 'package:flutter/material.dart';
import '../../app/theme/brain_theme.dart';
import '../home/home_screen.dart';
import '../games/games_screen.dart';
import '../progress/progress_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  final pages = const [HomeScreen(), GamesScreen(), ProgressScreen()];
  static const destinations = [
    (Icons.today_rounded, 'Today'),
    (Icons.fitness_center_rounded, 'Train'),
    (Icons.insights_rounded, 'Insights'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: index, children: pages),
    bottomNavigationBar: SafeArea(
      top: false,
      child: SizedBox(
        height: 96,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              height: 78,
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: context.brain.hud,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.brain.outline, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: context.brain.shadow,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(
                  destinations.length,
                  (i) => Expanded(
                    child: _DockItem(
                      icon: destinations[i].$1,
                      label: destinations[i].$2,
                      selected: index == i,
                      onTap: () => setState(() => index = i),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: label,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected ? context.brain.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            border: selected
                ? Border.all(color: context.brain.outline, width: 2)
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: context.brain.shadow,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 25,
                color: selected
                    ? context.onColor(context.brain.primary)
                    : context.brain.text.withValues(alpha: .7),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  height: 1.1,
                  color: selected
                      ? context.onColor(context.brain.primary)
                      : context.brain.text.withValues(alpha: .7),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
