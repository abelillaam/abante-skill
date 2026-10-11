import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../widgets/update_dialog.dart';
import 'dashboard/dashboard_screen.dart';
import 'lesson/ide_workspace_screen.dart';
import 'profile/profile_screen.dart';
import 'trivia/trivia_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _onDestinationSelected(int index) {
    setState(() => _index = index);
    // Tabs stay alive in the IndexedStack, so tell them to pick up any
    // progress made elsewhere (XP, streak, hearts, certificates).
    SessionService.requestRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return UpdateCheck(
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [DashboardScreen(), IdeWorkspaceScreen(lesson: null), TriviaScreen(), ProfileScreen()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onDestinationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded),
              label: 'Learn',
            ),
            NavigationDestination(
              icon: Icon(Icons.code_outlined),
              selectedIcon: Icon(Icons.code_rounded),
              label: 'Code',
            ),
            NavigationDestination(
              icon: Icon(Icons.quiz_outlined),
              selectedIcon: Icon(Icons.quiz_rounded),
              label: 'Quiz',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
