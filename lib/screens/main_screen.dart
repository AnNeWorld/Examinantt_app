import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../constants/app_colors.dart';
import 'home_screen.dart';
import 'test_series_screen.dart';
import 'resources_screen.dart';
import 'profile_screen.dart';
import 'courses_screen.dart';

import 'package:provider/provider.dart';
import '../providers/user_provider.dart';


import '../providers/theme_provider.dart';

import '../widgets/app_drawer.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      HomeScreen(
        onSelectTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const CoursesScreen(),
      const TestSeriesScreen(),
      const ResourcesScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, ThemeProvider>(
      builder: (context, userProvider, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        return PopScope(
          canPop: _currentIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_currentIndex != 0) {
              setState(() {
                _currentIndex = 0;
              });
            }
          },
          child: Scaffold(
            backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
            drawer: AppDrawer(
              currentIndex: _currentIndex,
              onSelectTab: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            body: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: isDark ? AppColors.accent : AppTheme.primaryColor,
              unselectedItemColor: isDark ? Colors.white60 : Colors.grey.shade600,
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.school_outlined), activeIcon: Icon(Icons.school), label: 'Batches'),
                BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Tests'),
                BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), activeIcon: Icon(Icons.library_books), label: 'Resources'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
          ),
        );
      },
    );
  }
}
