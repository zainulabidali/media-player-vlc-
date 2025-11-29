// FILE: lib/screens/audio_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';
import '../widgets/audio_tile.dart';
import '../providers/player_provider.dart';
import '../constants.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});
  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  @override
  void initState() {
    super.initState();
    final mp = Provider.of<MediaProvider>(context, listen: false);
    if (mp.audios.isEmpty) mp.scan();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mp, _) {
        if (mp.loading) return const Center(child: CircularProgressIndicator());
        final audios = mp.audios;
        if (audios.isEmpty) return const Center(child: Text('No audio found', style: TextStyle(color: AppColors.text)));
        return ListView.separated(
          padding: const EdgeInsets.all(Sizes.padding),
          itemCount: audios.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final m = audios[i];
            return AudioTile(
              media: m,
              onTap: () {
                Provider.of<PlayerProvider>(context, listen: false).openAudio(m.path);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playing audio')));
              },
            );
          },
        );
      },
    );
  }
}
