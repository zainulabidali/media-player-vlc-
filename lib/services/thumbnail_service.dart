// FILE: lib/services/thumbnail_service.dart
import 'dart:io';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

/// Generates a thumbnail image for a video and caches it to app directory.
class ThumbnailService {
  Future<String?> generate(String videoPath, {int timeMs = 1000}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumb = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
        timeMs: timeMs,
      );
      return thumb; // may be null
    } catch (e) {
      return null;
    }
  }
}
