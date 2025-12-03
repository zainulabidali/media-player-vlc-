// FILE: lib/services/media_database.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/media_file.dart';

class MediaDatabase {
  static const String _boxName = 'media_files';
  static const String _lastScanKey = 'last_scan_timestamp';

  late Box<dynamic> _box;

  Future<void> init() async {
    // Register adapter if needed (for Hive)
    // Hive.registerAdapter(MediaFileAdapter());

    _box = await Hive.openBox(_boxName);
    print("Media database initialized with ${_box.length} entries");
  }

  // Save a media file
  Future<void> saveMediaFile(MediaFile mediaFile) async {
    print(
        "Saving media file: ${mediaFile.path}, thumbnail: ${mediaFile.thumbnailPath}");
    await _box.put(mediaFile.path, mediaFile.toJson());
  }

  // Get a media file by path
  MediaFile? getMediaFile(String path) {
    final data = _box.get(path);
    if (data != null && data is Map) {
      final jsonData = Map<String, dynamic>.from(data);

      // Validate the data
      if (jsonData['path'] == null || jsonData['name'] == null) {
        print("Invalid media file data for path: $path");
        return null;
      }

      final mediaFile = MediaFile.fromJson(jsonData);
      print(
          "Retrieved media file: $path, thumbnail: ${mediaFile.thumbnailPath}");
      return mediaFile;
    }
    return null;
  }

  // Get all media files
  List<MediaFile> getAllMediaFiles() {
    final List<MediaFile> files = [];
    for (final key in _box.keys) {
      if (key is String) {
        final data = _box.get(key);
        if (data != null && data is Map) {
          try {
            final jsonData = Map<String, dynamic>.from(data);

            // Validate the data
            if (jsonData['path'] != null && jsonData['name'] != null) {
              files.add(MediaFile.fromJson(jsonData));
            }
          } catch (e) {
            print("Error parsing media file data for key: $key, error: $e");
          }
        }
      }
    }
    print("Retrieved ${files.length} media files from database");
    return files;
  }

  // Delete a media file
  Future<void> deleteMediaFile(String path) async {
    await _box.delete(path);
  }

  // Clear all media files
  Future<void> clearAll() async {
    await _box.clear();
    print("Cleared all media files from database");
  }

  // Get last scan timestamp
  DateTime? getLastScanTimestamp() {
    final timestamp = _box.get(_lastScanKey);
    if (timestamp != null && timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  // Set last scan timestamp
  Future<void> setLastScanTimestamp(DateTime timestamp) async {
    await _box.put(_lastScanKey, timestamp.millisecondsSinceEpoch);
  }

  // Close the database
  Future<void> close() async {
    await _box.close();
  }
}
