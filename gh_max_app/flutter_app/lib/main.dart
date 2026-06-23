// GH-Max App - 主入口文件

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/chart_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/ai_screen.dart';
import 'utils/theme.dart';
import 'utils/theme_manager.dart';
import 'utils/navigation_manager.dart';

void main() {
  runApp(const GHMaxApp());
}

class GHMaxApp extends StatefulWidget {
  const GHMaxApp({super.key});

  @override
  State<GHMaxApp> createState() => _GHMaxAppState();
}

class _GHMaxAppState extends State<GHMaxApp> {
  final ThemeManager _themeManager = ThemeManager.instance;

  @override
  void initState() {
    super.initState();
    _themeManager.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _themeManager.removeListener(() {
      setState(() {});
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GH-Max',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeManager.themeMode,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final NavigationManager _navManager = NavigationManager.instance;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ChartScreen(),
    const AIScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _navManager.addListener(_onNavigationRequest);
  }

  @override
  void dispose() {
    _navManager.removeListener(_onNavigationRequest);
    super.dispose();
  }

  void _onNavigationRequest() {
    final tabIndex = _navManager.consumePendingTab();
    if (tabIndex != null && tabIndex >= 0 && tabIndex < _screens.length) {
      setState(() {
        _currentIndex = tabIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.show_chart),
            label: '图表',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: '历史',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}