// GH-Max App

import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/chart_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/ai_screen.dart';
import 'utils/theme.dart';
import 'utils/theme_manager.dart';
import 'utils/navigation_manager.dart';

Future<void> _startBackend() async {
  try {
    // Check if backend is actually healthy (not just port open)
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/')).timeout(Duration(seconds: 1));
      if (response.statusCode == 200) return; // Already running and healthy
    } catch (_) {}
    
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final backendDir = '$exeDir\\..\\backend';
    
    // Kill any stale backend process first
    try { await Process.run('taskkill', ['/F', '/IM', 'gh_max_backend.exe']); } catch (_) {}
    await Future.delayed(Duration(milliseconds: 500));
    
    // Start fresh backend
    final backendExe = '$backendDir\\gh_max_backend.exe';
    await Process.start(backendExe, [], workingDirectory: backendDir, mode: ProcessStartMode.detached);
    
    // Wait for backend to become healthy (up to 10 seconds)
    for (int i = 0; i < 10; i++) {
      await Future.delayed(Duration(seconds: 1));
      try {
        final response = await http.get(Uri.parse('http://localhost:5000/')).timeout(Duration(seconds: 1));
        if (response.statusCode == 200) return;
      } catch (_) {}
    }
  } catch (_) {}
}

Future<void> _shutdownBackend() async {
  try {
    await http.post(Uri.parse('http://localhost:5000/api/shutdown')).timeout(Duration(seconds: 2));
  } catch (_) {
    try { await Process.run('taskkill', ['/F', '/IM', 'gh_max_backend.exe']); } catch (_) {}
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _startBackend();
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
    _themeManager.addListener(_onThemeChange);
  }

  void _onThemeChange() => setState(() {});

  @override
  void dispose() {
    _themeManager.removeListener(_onThemeChange);
    _shutdownBackend();
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
      setState(() { _currentIndex = tabIndex; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() { _currentIndex = index; }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart_outlined), activeIcon: Icon(Icons.show_chart), label: '图表'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), activeIcon: Icon(Icons.smart_toy), label: 'AI'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: '历史'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
