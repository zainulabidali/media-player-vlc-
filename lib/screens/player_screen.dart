import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../providers/player_provider.dart';
import '../widgets/player_controls.dart';
import '../constants.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoadingState();
  }

  void _checkLoadingState() {
    // Check periodically if video is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        final pp = Provider.of<PlayerProvider>(context, listen: false);
        // For media_kit, we check if the player has loaded tracks
        if (pp.availableAudioTracks.isNotEmpty ||
            pp.availableSubtitleTracks.isNotEmpty) {
          setState(() {
            _isLoading = false;
          });
        } else {
          // Keep checking
          _checkLoadingState();
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pp = Provider.of<PlayerProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          pp.player.state.playlist.medias.isNotEmpty
              ? pp.player.state.playlist.medias.first.uri
              : "",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading && pp.player.state.playlist.medias.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                  SizedBox(height: 12),
                  Text("Loading video...",
                      style: TextStyle(color: AppColors.text)),
                ],
              ),
            )
          : pp.player.state.playlist.medias.isEmpty
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
                      child: Video(
                        controller: pp.videoController,
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
