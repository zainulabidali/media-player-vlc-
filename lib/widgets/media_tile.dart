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
              child: media.thumbnailPath != null
                  ? Image.file(
                      File(media.thumbnailPath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.black26,
                      child: const Icon(Icons.play_circle_fill, size: 48),
                    ),
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
}
