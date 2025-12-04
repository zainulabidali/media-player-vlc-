import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../providers/player_provider.dart';
import '../constants.dart';

class PlayerControls extends StatefulWidget {
  const PlayerControls({super.key});

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  @override
  Widget build(BuildContext context) {
    final pp = Provider.of<PlayerProvider>(context, listen: true);

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
              const SizedBox(height: 20),

              // --- PROGRESS BAR ---
              StreamBuilder<Duration>(
                  stream: pp.player.stream.position,
                  builder: (context, snapshot) {
                    final duration = pp.player.state.duration;
                    final position = snapshot.data ?? Duration.zero;

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:Container(
                        height: 30,
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: StreamBuilder<Duration>(
                          stream: pp.player.stream.position,
                          builder: (context, snapshot) {
                            final duration = pp.player.state.duration;
                            final position = snapshot.data ?? Duration.zero;
                            final value = duration.inMilliseconds > 0
                                ? position.inMilliseconds /
                                    duration.inMilliseconds
                                : 0.0;

                            return SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.red,
                                inactiveTrackColor:
                                    Colors.white.withOpacity(0.25),
                                thumbColor: Colors.red,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 16),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: value.clamp(0.0, 1.0).toDouble(),
                                onChanged: (newValue) {
                                  if (duration.inMilliseconds > 0) {
                                    final newPosition = Duration(
                                      milliseconds:
                                          (newValue * duration.inMilliseconds)
                                              .toInt(),
                                    );
                                    pp.seekVideo(newPosition);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),

              const SizedBox(height: 5),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- Audio Track Selection ---
              if (pp.availableAudioTracks.isNotEmpty) ...[
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        _showAudioAndSubtitleDetails(context);
                      },
                      icon: Icon(Icons.subtitles,
                          size: 18, color: AppColors.text),
                    ),
                  ],
                ),
              ],
              SizedBox(
                width: 10,
              ),
              // Rewind 10
              _roundButton(
                icon: Icons.replay_10,
                onTap: () async {
                  final currentPosition = pp.player.state.position;
                  final newPos = currentPosition - const Duration(seconds: 10);
                  await pp.seekVideo(
                      newPos >= Duration.zero ? newPos : Duration.zero);
                },
              ),

              const SizedBox(width: 20),

              // Play / Pause
              _roundButton(
                icon: pp.isVideoPlaying ? Icons.pause : Icons.play_arrow,
                size: 38,
                onTap: () => pp.toggleVideoPlay(),
              ),

              const SizedBox(width: 20),

              // Forward 10
              _roundButton(
                icon: Icons.forward_10,
                onTap: () async {
                  final currentPosition = pp.player.state.position;
                  final duration = pp.player.state.duration;
                  final newPos = currentPosition + const Duration(seconds: 10);
                  await pp.seekVideo(newPos <= duration ? newPos : duration);
                },
              ),
              SizedBox(
                width: 5,
              ),
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
                        value: pp.player.state.rate,
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
                          if (v != null) pp.player.setRate(v);
                          pp.notifyListeners();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Show audio tracks and subtitle details in a bottom sheet
  void _showAudioAndSubtitleDetails(BuildContext context) {
    final pp = Provider.of<PlayerProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Audio Tracks Section
              if (pp.availableAudioTracks.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 10, left: 20),
                  child: Text(
                    'Audio',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: pp.availableAudioTracks.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == pp.selectedAudioTrackIndex;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 16.0),
                        child: ChoiceChip(
                          label: Text(
                              pp.availableAudioTracks[index].title ??
                                  'Track ${index + 1}',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 11)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _handleAudioTrackSelection(context, index);
                            }
                          },
                          selectedColor: const Color.fromARGB(0, 248, 249, 249),
                          // backgroundColor: Colors.grey.withOpacity(0.3),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Subtitles Section
              if (pp.availableSubtitleTracks.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: Text(
                    'Subtitles',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: pp.availableSubtitleTracks.length +
                        1, // +1 for "None" option
                    itemBuilder: (context, index) {
                      // Index 0 is "None", then subtitle tracks
                      final isNoneSelected =
                          index == 0 && pp.selectedSubtitleTrackIndex == -1;
                      final isTrackSelected = index > 0 &&
                          (index - 1) == pp.selectedSubtitleTrackIndex;
                      final isSelected = isNoneSelected || isTrackSelected;

                      if (index == 0) {
                        // None option
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 16.0),
                          child: ChoiceChip(
                            label: const Text('None',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _handleSubtitleTrackSelection(context, -1);
                              }
                            },
                            selectedColor:
                                const Color.fromARGB(0, 248, 249, 249),
                          ),
                        );
                      } else {
                        // Subtitle track
                        final trackIndex = index - 1;
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 16.0),
                          child: ChoiceChip(
                            label: Text(
                                pp.availableSubtitleTracks[trackIndex].title ??
                                    'Subtitle ${trackIndex + 1}',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _handleSubtitleTrackSelection(
                                    context, trackIndex);
                              }
                            },
                            selectedColor:
                                const Color.fromARGB(0, 248, 249, 249),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ] else ...[
                // Subtitles Section (Placeholder for when no subtitle tracks available)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: Text(
                    'Subtitles',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  child: ListTile(
                    title: const Text('No subtitle tracks available'),
                    tileColor: Colors.grey.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Handle audio track selection
  void _handleAudioTrackSelection(BuildContext context, int index) {
    final pp = Provider.of<PlayerProvider>(context, listen: false);
    pp.selectAudioTrack(index);
  }

  // Handle subtitle track selection
  void _handleSubtitleTrackSelection(BuildContext context, int index) {
    final pp = Provider.of<PlayerProvider>(context, listen: false);
    pp.selectSubtitleTrack(index);
  }

  // --- Reusable rounded glass button ---
  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 20,
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
