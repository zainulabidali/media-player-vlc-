// FILE: lib/services/media_service.dart
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../models/media_file.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;

class MediaService {
  final List<String> _videoExt = ['.mp4', '.mkv', '.webm', '.avi'];
  final List<String> _audioExt = ['.mp3', '.wav', '.m4a', '.flac'];

  /// Request correct permissions for Android 11+ and older.
  Future<bool> requestPermissions() async {
    // On web, no permission handling is needed
    if (kIsWeb) {
      return true;
    }

    // First try Android 11+ full access
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) {
      return true;
    }

    // Fallback for Android 10 and below
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  Future<List<MediaFile>> scanDeviceForMedia() async {
    final granted = await requestPermissions();
    if (!granted && !kIsWeb) {
      print("❌ Permissions not granted");
      return [];
    }

    print("✅ Permission granted. Scanning...");
    // EXPANDED list of directories for different devices
    final dirs = <Directory>[
      Directory('/storage/emulated/0/Movies'),
      Directory('/storage/emulated/0/DCIM'),
      Directory('/storage/emulated/0/DCIM/Camera'),
      Directory('/storage/emulated/0/Download'),
      Directory('/storage/emulated/0/Pictures'),
      Directory('/storage/emulated/0/Music'),
      Directory('/storage/emulated/0'),

      // Alternative mount point on many new devices
      Directory('/storage/self/primary/Movies'),
      Directory('/storage/self/primary/DCIM'),
      Directory('/storage/self/primary/Download'),
      Directory('/storage/self/primary'),
    ];

    final List<MediaFile> found = [];
    final visited = <String>{};

    // On web, we can't scan directories, so return empty list
    if (kIsWeb) {
      print("🌐 Web platform: Cannot scan device directories");
      return found;
    }

    // Scan directories concurrently for better performance
    await Future.wait(dirs.map((dir) async {
      if (!dir.existsSync()) {
        print("Skipping missing dir: ${dir.path}");
        return;
      }

      print("📂 Scanning: ${dir.path}");

      try {
        // Limit recursion depth to avoid deep scanning that takes too long
        await _scanDirectory(dir, found, visited, 0, 3); // Max depth of 3
      } catch (e) {
        print("⚠️ Error scanning directory: ${dir.path} -> $e");
      }
    }));

    print("🎉 Scan complete. Found ${found.length} media files.");
    return found;
  }

  // Recursive directory scanning with depth limit
  Future<void> _scanDirectory(
    Directory dir,
    List<MediaFile> found,
    Set<String> visited,
    int currentDepth,
    int maxDepth,
  ) async {
    if (currentDepth > maxDepth) return;

    try {
      final lister = dir.list(followLinks: false);
      await for (final entity in lister) {
        try {
          if (entity is File) {
            final ext = p.extension(entity.path).toLowerCase();
            final name = p.basename(entity.path);

            if (_videoExt.contains(ext) || _audioExt.contains(ext)) {
              if (visited.contains(entity.path)) continue;
              visited.add(entity.path);

              found.add(
                MediaFile(
                  path: entity.path,
                  name: name,
                  isVideo: _videoExt.contains(ext),
                ),
              );
            }
          } else if (entity is Directory && currentDepth < maxDepth) {
            // Continue scanning subdirectories but limit depth
            await _scanDirectory(
                entity, found, visited, currentDepth + 1, maxDepth);
          }
        } catch (e) {
          // Skip problematic files/directories
          print("⚠️ Error reading entity: $e");
        }
      }
    } catch (e) {
      // Skip directories that can't be accessed
      print("⚠️ Access denied to directory: ${dir.path}");
    }
  }
}
