import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/matches_screen.dart';
import '../screens/table_screen.dart';
import '../screens/schedule_screen.dart';
import '../theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  final pages = const [
    HomeScreen(),
    MatchesScreen(),
    TableScreen(),
    ScheduleScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF15161B).withOpacity(0.95),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                blurRadius: 18,
                offset: Offset(0, 10),
                color: Colors.black54,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BottomNavigationBar(
              currentIndex: index,
              onTap: (v) => setState(() => index = v),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppTheme.orange,
              unselectedItemColor: Colors.white70,
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Головне',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sports_soccer),
                  label: 'Матчі',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_rounded),
                  label: 'Таблиця',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_rounded),
                  label: 'Розклад',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
