import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../widgets/player_controls.dart';
import '../constants.dart';
import 'package:video_player/video_player.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pp = Provider.of<PlayerProvider>(context);
    final vc = pp.videoController;

    // Listen to video controller updates
    if (vc != null) {
      vc.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Player"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: vc == null || !vc.value.isInitialized
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.play_circle_filled_outlined,
                      size: 80, color: AppColors.accent),
                  SizedBox(height: 12),
                  Text("No video loaded",
                      style: TextStyle(color: AppColors.text)),
                ],
              ),
            )
          : Stack(
              children: [
                /// FULLSCREEN VIDEO
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: vc.value.size.width,
                      height: vc.value.size.height,
                      child: VideoPlayer(vc),
                    ),
                  ),
                ),

                /// PLAYER CONTROLS (Play/Pause/Seek)
                const Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: PlayerControls(),
                  ),
                ),

                /// BOTTOM INFORMATION PANEL OVERLAY
              ],
            ),
    );
  }
}
