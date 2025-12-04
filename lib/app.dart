// FILE: lib/app.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'constants.dart';
import 'screens/home_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _currentTheme = 'dark';

  @override
  void initState() {
    super.initState();
    _listenToThemeChanges();
  }

  void _listenToThemeChanges() async {
    try {
      // Listen for theme changes
      final box = Hive.isBoxOpen('events')
          ? Hive.box('events')
          : await Hive.openBox('events');

      box.listenable().addListener(() {
        if (box.containsKey('themeChanged')) {
          final newTheme = box.get('themeChanged');
          if (newTheme != _currentTheme) {
            setState(() {
              _currentTheme = newTheme;
            });
          }
        }
      });

      // Load initial theme
      final settingsBox = Hive.isBoxOpen('settings')
          ? Hive.box('settings')
          : await Hive.openBox('settings');
      final savedTheme = settingsBox.get('theme', defaultValue: 'dark');
      setState(() {
        _currentTheme = savedTheme;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JK Wave',
      debugShowCheckedModeBanner: false,
      theme: _currentTheme == 'light'
          ? ThemeData.light().copyWith(
              scaffoldBackgroundColor: const Color.fromARGB(255, 240, 239, 239),
              colorScheme: ColorScheme.light().copyWith(
                primary: AppColors.accent,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.orange[50],
                centerTitle: true,
                foregroundColor: Colors.black,
              ),
            )
          : ThemeData.dark().copyWith(
              scaffoldBackgroundColor: AppColors.background,
              colorScheme: ColorScheme.dark().copyWith(
                primary: AppColors.accent,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.surface,
                centerTitle: true,
              ),
            ),
      home: const HomeScreen(),
    );
  }
}
