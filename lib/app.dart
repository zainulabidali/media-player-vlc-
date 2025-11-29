// FILE: lib/app.dart
import 'package:flutter/material.dart';
import 'constants.dart';
import 'screens/home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VLC Clone Sample',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
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
