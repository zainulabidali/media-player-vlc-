// FILE: lib/services/thumbnail_service.dart
import 'dart:io';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Generates a thumbnail image for a video and caches it to app directory.
class ThumbnailService {
  // Cache for generated thumbnails
  final Map<String, String> _thumbnailCache = {};

  Future<String?> generate(String videoPath, {int timeMs = 500}) async {
    // Check cache first
    if (_thumbnailCache.containsKey(videoPath)) {
      print("Thumbnail cache hit for: $videoPath");
      return _thumbnailCache[videoPath];
    }

    try {
      // Validate video file exists
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        print("Video file does not exist: $videoPath");
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final thumbnailDir = Directory('${tempDir.path}/thumbnails');

      // Create thumbnail directory if it doesn't exist
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      // Generate unique filename for thumbnail
      final fileName = p.basenameWithoutExtension(videoPath);
      final sanitizedFileName = fileName.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
      final thumbnailPath =
          '${thumbnailDir.path}/${sanitizedFileName}_thumb.jpg';

      // Check if thumbnail already exists
      if (await File(thumbnailPath).exists()) {
        print("Thumbnail file exists for: $videoPath");
        _thumbnailCache[videoPath] = thumbnailPath;
        return thumbnailPath;
      }

      print("Generating thumbnail for: $videoPath");

      // Try to generate thumbnail with fallback options
      String? thumb;

      // First attempt with standard settings
      try {
        thumb = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: thumbnailPath,
          imageFormat: ImageFormat.JPEG,
          quality: 50,
          timeMs: timeMs,
          maxHeight: 180,
        );
      } catch (e) {
        print("First attempt failed for $videoPath: $e");
        // Second attempt with different settings
        try {
          thumb = await VideoThumbnail.thumbnailFile(
            video: videoPath,
            thumbnailPath: thumbnailPath,
            imageFormat: ImageFormat.JPEG,
            quality: 30,
            timeMs: 1000,
            maxHeight: 120,
          );
        } catch (e2) {
          print("Second attempt failed for $videoPath: $e2");
        }
      }

      if (thumb != null) {
        print("Thumbnail generated successfully for: $videoPath");
        _thumbnailCache[videoPath] = thumb;
      } else {
        print("Failed to generate thumbnail for: $videoPath");
      }

      return thumb;
    } catch (e) {
      print("Error generating thumbnail for $videoPath: $e");
      return null;
    }
  }

  // Clear cache
  void clearCache() {
    _thumbnailCache.clear();
  }

  // Clear all thumbnails from disk
  Future<void> clearAllThumbnails() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbnailDir = Directory('${tempDir.path}/thumbnails');
      if (await thumbnailDir.exists()) {
        await thumbnailDir.delete(recursive: true);
      }
    } catch (e) {
      print("Error clearing thumbnails: $e");
    }
  }
}
