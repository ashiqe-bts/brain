import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../games/games_screen.dart';
import '../home/home_screen.dart';
import '../progress/progress_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  static const pages = [HomeScreen(), GamesScreen(), ProgressScreen()];
  static const destinations = [
    (Icons.today_outlined, Icons.today_rounded, 'Today'),
    (Icons.fitness_center_outlined, Icons.fitness_center_rounded, 'Train'),
    (Icons.insights_outlined, Icons.insights_rounded, 'Insights'),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final expanded =
          constraints.maxWidth >= AppSettings.compactNavigationBreakpoint;
      final content = IndexedStack(index: index, children: pages);
      if (expanded) {
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (value) =>
                      setState(() => index = value),
                  extended:
                      constraints.maxWidth >=
                      AppSettings.extendedNavigationBreakpoint,
                  groupAlignment: -.72,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: _RailBrand(),
                  ),
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.$1),
                        selectedIcon: Icon(destination.$2),
                        label: Text(destination.$3),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          ),
        );
      }
      return Scaffold(
        body: content,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: .75,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            destinations: [
              for (final destination in destinations)
                NavigationDestination(
                  icon: Icon(destination.$1),
                  selectedIcon: Icon(destination.$2),
                  label: destination.$3,
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _RailBrand extends StatelessWidget {
  const _RailBrand();

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'BrainFlex',
    child: Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.blur_circular_rounded,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    ),
  );
}
