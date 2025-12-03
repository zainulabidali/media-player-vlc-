// FILE: lib/screens/audio_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';
import '../widgets/audio_tile.dart';
import '../services/audio_service.dart';
import '../screens/audio_player_screen.dart';
import '../constants.dart';

class AudioScreen extends StatelessWidget {
  const AudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mp, _) {
        if (mp.loading && mp.audios.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final audios = mp.audios;
        if (audios.isEmpty)
          return const Center(
              child: Text('No audio found',
                  style: TextStyle(color: AppColors.text)));
        return Consumer<AudioService>(builder: (context, audioService, _) {
          return ListView.separated(
            padding: const EdgeInsets.all(Sizes.padding),
            itemCount: audios.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final m = audios[i];
              return AudioTile(
                media: m,
                onTap: () {
                  // Play the audio using the audio service
                  audioService.playAudio(m);

                  // Navigate to the dedicated audio player screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AudioPlayerScreen(),
                    ),
                  );
                },
              );
            },
          );
        });
      },
    );
  }
}
