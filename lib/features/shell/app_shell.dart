import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../games/games_screen.dart';
import '../progress/progress_screen.dart';
import '../lab/lab_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  final pages = const [
    HomeScreen(),
    GamesScreen(),
    ProgressScreen(),
    LabScreen(),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: index, children: pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (v) => setState(() => index = v),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
        NavigationDestination(
          icon: Icon(Icons.sports_esports_rounded),
          label: 'Games',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_rounded),
          label: 'Progress',
        ),
        NavigationDestination(icon: Icon(Icons.science_rounded), label: 'Lab'),
      ],
    ),
  );
}
