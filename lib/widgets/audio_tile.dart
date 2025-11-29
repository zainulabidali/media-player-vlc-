// FILE: lib/widgets/audio_tile.dart
import 'package:flutter/material.dart';
import '../models/media_file.dart';
import '../constants.dart';

class AudioTile extends StatelessWidget {
  final MediaFile media;
  final VoidCallback onTap;
  const AudioTile({required this.media, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppColors.surface,
      leading: const Icon(Icons.music_note, size: 36, color: AppColors.accent),
      title: Text(media.name, style: const TextStyle(color: AppColors.text)),
      subtitle: Text(media.path, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}
