import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../constants.dart';
import 'package:video_player/video_player.dart';

class PlayerControls extends StatefulWidget {
  const PlayerControls({super.key});

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  @override
  Widget build(BuildContext context) {
    final pp = Provider.of<PlayerProvider>(context, listen: true);
    final vc = pp.videoController;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- CONTROL BUTTONS ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Now Playing",
                style: TextStyle(
                  color: Color.fromARGB(255, 251, 251, 251),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                vc?.dataSource ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 20),

              // --- PROGRESS BAR ---
              if (vc != null && vc.value.isInitialized)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: VideoProgressIndicator(
                    colors: VideoProgressColors(
                      playedColor: AppColors.accent,
                      bufferedColor:
                          const Color.fromARGB(31, 86, 55, 20).withOpacity(0.5),
                      backgroundColor: Colors.white.withOpacity(0.25),
                    ),
                    vc,
                    allowScrubbing: true,
                    padding: EdgeInsets.zero,
                  ),
                ),

              const SizedBox(height: 5),
            ],
          ),

          // --- Audio Track Selection ---
          if (pp.availableAudioTracks.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.audiotrack, size: 11, color: AppColors.text),
                const SizedBox(width: 8),
                const Text("Audio Track:",
                    style: TextStyle(color: AppColors.text, fontSize: 10)),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: pp.selectedAudioTrackIndex,
                    dropdownColor: Colors.black87,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                    ),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppColors.text, size: 18),
                    items:
                        List.generate(pp.availableAudioTracks.length, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text(
                          pp.availableAudioTracks[index].language,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }),
                    onChanged: (index) {
                      if (index != null) {
                        // Handle audio track selection
                        _handleAudioTrackSelection(context, index);
                      }
                    },
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 12),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(0, 0, 0, 0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color.fromARGB(0, 255, 255, 255)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<double>(
                        value: vc?.value.playbackSpeed ?? 1.0,
                        dropdownColor: Colors.black87,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                        ),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: AppColors.text),
                        items: const [
                          DropdownMenuItem(value: 0.5, child: Text("0.5x")),
                          DropdownMenuItem(value: 1.0, child: Text("1x")),
                          DropdownMenuItem(value: 1.5, child: Text("1.5x")),
                          DropdownMenuItem(value: 2.0, child: Text("2x")),
                        ],
                        onChanged: (v) {
                          if (v != null) vc?.setPlaybackSpeed(v);

                          // Force UI update by notifying provider
                          pp.notifyListeners();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              // Rewind 10
              _roundButton(
                icon: Icons.replay_10,
                onTap: () async {
                  if (vc != null && vc.value.isInitialized) {
                    final newPos =
                        vc.value.position - const Duration(seconds: 10);
                    await vc.seekTo(
                      newPos >= Duration.zero ? newPos : Duration.zero,
                    );

                    // Also seek the audio track if one is selected
                    if (pp.selectedAudioTrackIndex > 0 &&
                        pp.availableAudioTracks.isNotEmpty) {
                      await pp.audioPlayer.seek(
                          newPos >= Duration.zero ? newPos : Duration.zero);
                    }
                  }
                },
              ),

              const SizedBox(width: 20),

              // Play / Pause
              _roundButton(
                icon: vc != null && vc.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                size: 38,
                onTap: () => pp.toggleVideoPlay(),
              ),

              const SizedBox(width: 20),

              // Forward 10
              _roundButton(
                icon: Icons.forward_10,
                onTap: () async {
                  if (vc != null && vc.value.isInitialized) {
                    final pos = vc.value.position + const Duration(seconds: 10);
                    final dur = vc.value.duration;
                    await vc.seekTo(pos <= dur ? pos : dur);

                    // Also seek the audio track if one is selected
                    if (pp.selectedAudioTrackIndex > 0 &&
                        pp.availableAudioTracks.isNotEmpty) {
                      await pp.audioPlayer.seek(pos <= dur ? pos : dur);
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Handle audio track selection with error handling
  void _handleAudioTrackSelection(BuildContext context, int index) {
    final pp = Provider.of<PlayerProvider>(context, listen: false);

    pp.selectAudioTrack(index).catchError((error) {
      // Show error message if track selection fails
      if (Scaffold.maybeOf(context) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load audio track: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  // --- Reusable rounded glass button ---
  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 30,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onTap,
        child: Icon(
          icon,
          size: size,
          color: const Color.fromARGB(255, 255, 255, 255),
        ),
      ),
    );
  }
}
