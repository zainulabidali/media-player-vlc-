// FILE: lib/screens/home_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_nav.dart';
import 'videos_screen.dart';
import 'audio_screen.dart';
import 'files_screen.dart';
import 'settings_screen.dart';
import 'player_screen.dart';
import '../providers/player_provider.dart';
import '../providers/media_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final List<Widget> _tabs = const [
    VideosScreen(),
    AudioScreen(),
    FilesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _listenToThemeChanges();
    _triggerInitialScan();
  }

  void _triggerInitialScan() {
    // Trigger initial scan after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      mediaProvider.scan();
    });
  }

  void _listenToThemeChanges() async {
    try {
      // Listen for theme changes to rebuild UI
      final box = Hive.isBoxOpen('events')
          ? Hive.box('events')
          : await Hive.openBox('events');

      box.listenable().addListener(() {
        if (box.containsKey('themeChanged')) {
          // Rebuild the UI when theme changes
          setState(() {});
        }
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    Provider.of<PlayerProvider>(context, listen: false).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pp = Provider.of<PlayerProvider>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 10,
            ),
            Image(
              image: AssetImage("assets/Picsart_25-12-03_09-44-34-316.png"),
              height: 24,
            ),
            SizedBox(width: 5,),
            Text('Vlc'),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: _tabs[_index],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini player (simple)
          if (pp.videoController != null || pp.audioPlayer.playing)
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlayerScreen()),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _getMiniPlayerBackgroundColor(),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _getMiniPlayerBorderColor(),
                        width: 0.1,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                        ),

                        // Now Playing text
                        const Expanded(
                          child: Text(
                            'Now Playing',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        // Stop button
                        IconButton(
                          icon: const Icon(
                            Icons.stop_circle,
                            color: Color.fromARGB(255, 163, 61, 61),
                          ),
                          onPressed: () {
                            if (pp.videoController != null) {
                              pp.disposeVideo();
                            } else {
                              pp.stopAudio();
                            }
                          },
                        ),
                        // Play/Pause button
                        IconButton(
                          icon: Icon(
                            pp.isVideoPlaying || pp.isAudioPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          onPressed: () {
                            if (pp.videoController != null) {
                              pp.toggleVideoPlay();
                            } else {
                              pp.toggleAudioPlay();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          VLCBottomNav(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
          ),
        ],
      ),
    );
  }

  Color _getMiniPlayerBackgroundColor() {
    // Return appropriate color based on current theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);
  }

  Color _getMiniPlayerBorderColor() {
    // Return appropriate color based on current theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode
        ? Colors.white.withOpacity(0.25)
        : Colors.black.withOpacity(0.1);
  }
}
