// FILE: lib/widgets/media_tile.dart
import 'dart:io';

import 'package:flutter/material.dart';
import '../models/media_file.dart';
import '../constants.dart';

class MediaTile extends StatelessWidget {
  final MediaFile media;
  final VoidCallback onTap;
  const MediaTile({required this.media, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildMediaContent(),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                media.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    if (media.thumbnailPath != null && media.thumbnailPath!.isNotEmpty) {
      return _buildThumbnailImage();
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildThumbnailImage() {
    return Image.file(
      File(media.thumbnailPath!),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Log the error for debugging
        print(
            "Failed to load thumbnail: ${media.thumbnailPath}, error: $error");
        // Fallback to placeholder
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    IconData icon;
    Color color;

    if (media.isVideo) {
      icon = Icons.play_circle_outline_rounded;
      color = const Color.fromARGB(255, 121, 120, 118);
    } else {
      icon = Icons.music_note;
      color = AppColors.text;
    }

    return Container(
      color: Colors.black26,
      child: Center(
        child: Icon(
          icon,
          size: 48,
          color: color,
        ),
      ),
    );
  }
}
