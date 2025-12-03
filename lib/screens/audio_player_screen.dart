// FILE: lib/screens/audio_player_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../models/media_file.dart';
import '../constants.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = Provider.of<AudioService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Just pop the screen, don't stop playback
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Consumer<AudioService>(
        builder: (context, audioService, _) {
          final currentMedia = audioService.currentMedia;
          final isPlaying = audioService.isPlaying;
          final duration = audioService.duration;
          final position = audioService.position;
          final queue = audioService.queue;
          final currentIndex = audioService.currentIndex;
          final isLooping = audioService.isLooping;
          final isShuffling = audioService.isShuffling;
          final playbackSpeed = audioService.playbackSpeed;

          // Calculate seek value
          double seekValue = 0.0;
          if (duration != null && duration.inMilliseconds > 0) {
            seekValue = position.inMilliseconds / duration.inMilliseconds;
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Album art or waveform
                _buildAlbumArt(currentMedia),

                // Song info
                _buildSongInfo(currentMedia),

                // Progress bar
                _buildProgressBar(seekValue, position, duration),

                // Controls
                _buildControls(audioService, isPlaying),

                // Additional controls
                _buildAdditionalControls(
                    audioService, isLooping, isShuffling, playbackSpeed),

                // Queue list
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlbumArt(MediaFile? media) {
    return Container(
      height: 300,
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: media != null
          ? Center(
              child: Icon(
                Icons.music_note,
                size: 100,
                color: const Color.fromARGB(255, 239, 239, 239),
              ),
            )
          : const Center(
              child: Icon(
                Icons.music_note,
                size: 100,
                color: AppColors.accent,
              ),
            ),
    );
  }

  Widget _buildSongInfo(MediaFile? media) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            media?.name ?? 'Unknown Title',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            media?.path.split('/').last.split('.').first ?? 'Unknown Artist',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
      double seekValue, Duration position, Duration? duration) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.surface,
              thumbColor: AppColors.accent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
            ),
            child: Slider(
              value: seekValue.clamp(0.0, 1.0),
              onChanged: (value) {
                // Seek to the new position
                if (duration != null) {
                  final newPosition = Duration(
                    milliseconds: (value * duration.inMilliseconds).toInt(),
                  );
                  _audioService.seek(newPosition);
                }
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(position)),
              Text(duration != null ? _formatDuration(duration) : '--:--'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(AudioService audioService, bool isPlaying) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            iconSize: 40,
            icon: const Icon(Icons.skip_previous),
            onPressed: audioService.queue.length > 1
                ? audioService.skipToPrevious
                : null,
          ),
          FloatingActionButton(
            backgroundColor: AppColors.accent,
            onPressed: audioService.togglePlayPause,
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              size: 40,
              color: Colors.white,
            ),
          ),
          IconButton(
            iconSize: 40,
            icon: const Icon(Icons.skip_next),
            onPressed:
                audioService.queue.length > 1 ? audioService.skipToNext : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalControls(AudioService audioService, bool isLooping,
      bool isShuffling, double playbackSpeed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              isShuffling ? Icons.shuffle : Icons.shuffle_outlined,
              color: isShuffling ? AppColors.accent : null,
            ),
            onPressed: audioService.toggleShuffling,
          ),
          IconButton(
            icon: Icon(
              isLooping ? Icons.repeat : Icons.repeat_outlined,
              color: isLooping ? AppColors.accent : null,
            ),
            onPressed: audioService.toggleLooping,
          ),
          PopupMenuButton<double>(
            icon: const Icon(Icons.speed),
            onSelected: (speed) {
              audioService.setPlaybackSpeed(speed);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0.5, child: Text('0.5x')),
              const PopupMenuItem(value: 0.75, child: Text('0.75x')),
              const PopupMenuItem(value: 1.0, child: Text('1.0x')),
              const PopupMenuItem(value: 1.25, child: Text('1.25x')),
              const PopupMenuItem(value: 1.5, child: Text('1.5x')),
              const PopupMenuItem(value: 2.0, child: Text('2.0x')),
            ],
          ),
        ],
      ),
    );
  }

 

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
