// FILE: lib/screens/home_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_nav.dart';
import 'videos_screen.dart';
import 'audio_screen.dart';
import 'files_screen.dart';
import 'settings_screen.dart';
import 'player_screen.dart';
import '../providers/player_provider.dart';

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
  void dispose() {
    Provider.of<PlayerProvider>(context, listen: false).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pp = Provider.of<PlayerProvider>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: const Text('VLC'),
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
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 0.1,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20,),
                       
                        // Now Playing text
                        const Expanded(
                          child: Text(
                            'Now Playing',
                            style: TextStyle(
                              color: Colors.white,
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
                            color: Colors.white,
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
}
