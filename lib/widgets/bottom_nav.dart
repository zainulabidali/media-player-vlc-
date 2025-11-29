// FILE: lib/widgets/bottom_nav.dart
import 'package:flutter/material.dart';
import '../constants.dart';

class VLCBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const VLCBottomNav({required this.currentIndex, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: Colors.white70,
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Videos'),
        BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Audio'),
        BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Files'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
