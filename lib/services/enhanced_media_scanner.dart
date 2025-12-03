// FILE: lib/services/enhanced_media_scanner.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import '../models/media_file.dart';
import 'media_database.dart';
import 'thumbnail_service.dart';
import 'package:video_player/video_player.dart';

class EnhancedMediaScanner {
  static final EnhancedMediaScanner _instance =
      EnhancedMediaScanner._internal();
  factory EnhancedMediaScanner() => _instance;
  EnhancedMediaScanner._internal();

  final MediaDatabase _database = MediaDatabase();
  final ThumbnailService _thumbnailService = ThumbnailService();
  final List<String> _videoExt = [
    '.mp4',
    '.mkv',
    '.webm',
    '.avi',
    '.mov',
    '.wmv',
    '.flv',
    '.m4v'
  ];
  final List<String> _audioExt = [
    '.mp3',
    '.wav',
    '.m4a',
    '.flac',
    '.aac',
    '.ogg',
    '.wma',
    '.opus'
  ];

  // Scanning state
  bool _isScanning = false;
  final StreamController<List<MediaFile>> _mediaStreamController =
      StreamController<List<MediaFile>>.broadcast();

  Stream<List<MediaFile>> get mediaStream => _mediaStreamController.stream;
  bool get isScanning => _isScanning;

  Future<void> init() async {
    await _database.init();
  }

  /// Request correct permissions for Android 11+ and older.
  Future<bool> _requestPermissions() async {
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

  /// Get cached media files from database for instant loading
  Future<List<MediaFile>> getCachedMedia() async {
    return _database.getAllMediaFiles();
  }

  /// Scan for media files with incremental updates
  Future<void> scanMedia({bool forceRescan = false}) async {
    if (_isScanning) return;

    _isScanning = true;

    try {
      // For first launch or force rescan, clear database
      final lastScan = _database.getLastScanTimestamp();
      if (lastScan == null || forceRescan) {
        print("Clearing database for fresh scan");
        await _database.clearAll();
      }

      // Get cached media for immediate UI update
      final cachedMedia = await getCachedMedia();
      print("Loaded ${cachedMedia.length} cached media files");
      _mediaStreamController.add(cachedMedia);

      // On web, we can't scan directories
      if (kIsWeb) {
        print("🌐 Web platform: Cannot scan device directories");
        _isScanning = false;
        return;
      }

      final granted = await _requestPermissions();
      if (!granted) {
        print("❌ Permissions not granted");
        _isScanning = false;
        return;
      }

      print("✅ Permission granted. Scanning...");

      // Common directories to scan
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

      final visited = <String>{};
      final newMediaFiles = <MediaFile>[];

      // Scan directories concurrently
      await Future.wait(dirs.map((dir) async {
        if (!dir.existsSync()) {
          print("Skipping missing dir: ${dir.path}");
          return;
        }

        print("📂 Scanning: ${dir.path}");
        await _scanDirectory(dir, newMediaFiles, visited, 0, 3);
      }));

      print("Found ${newMediaFiles.length} media files to process");

      // Process and update media files
      await _processMediaFiles(newMediaFiles);

      // Update last scan timestamp
      await _database.setLastScanTimestamp(DateTime.now());

      // Send final update
      final finalMedia = await getCachedMedia();
      print("Final media count: ${finalMedia.length}");
      _mediaStreamController.add(finalMedia);

      print("🎉 Scan complete. Found ${finalMedia.length} media files.");
    } catch (e) {
      print("Error during scan: $e");
    } finally {
      _isScanning = false;
    }
  }

  /// Check if a file should be included in the scan
  bool _shouldIncludeFile(String fileName, String extension) {
    // Filter out temporary files, trash files, and hidden files
    if (fileName.startsWith('.') ||
        fileName.contains('.tmp') ||
        fileName.contains('.temp') ||
        fileName.contains('.trash') ||
        fileName.contains('.Trash') ||
        fileName.contains('trashed-') ||
        fileName.contains('TRASHED-')) {
      return false;
    }

    // Check if it's a valid media extension
    return _videoExt.contains(extension) || _audioExt.contains(extension);
  }

  /// Recursive directory scanning with depth limit
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

            // Check if this is a valid media file
            if (_shouldIncludeFile(name, ext)) {
              if (visited.contains(entity.path)) continue;
              visited.add(entity.path);

              // Check if file already exists in database and is up to date
              final existing = _database.getMediaFile(entity.path);
              final lastModified = await entity.lastModified();

              if (existing != null &&
                  existing.lastModified != null &&
                  existing.lastModified!.millisecondsSinceEpoch >=
                      lastModified.millisecondsSinceEpoch) {
                // File hasn't changed, use existing data
                print("Using cached data for: ${entity.path}");
                found.add(existing);
              } else {
                // File is new or modified, create new entry
                print("Found new/modified file: ${entity.path}");
                final mediaFile = MediaFile(
                  path: entity.path,
                  name: name,
                  isVideo: _videoExt.contains(ext),
                  size: await entity.length(),
                  lastModified: lastModified,
                );
                found.add(mediaFile);
              }
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

  /// Process media files - extract metadata and generate thumbnails
  Future<void> _processMediaFiles(List<MediaFile> mediaFiles) async {
    const chunkSize = 5; // Reduced chunk size for better performance

    print("Processing ${mediaFiles.length} media files");

    for (int i = 0; i < mediaFiles.length; i += chunkSize) {
      final endIndex = (i + chunkSize < mediaFiles.length)
          ? i + chunkSize
          : mediaFiles.length;
      final chunk = mediaFiles.sublist(i, endIndex);

      print(
          "Processing chunk ${i ~/ chunkSize + 1}/${(mediaFiles.length + chunkSize - 1) ~/ chunkSize}");

      // Process this chunk concurrently
      await Future.wait(chunk.map((mediaFile) async {
        try {
          MediaFile processedFile = mediaFile;

          // Extract metadata
          processedFile = await _extractMetadata(mediaFile);

          // Generate thumbnail for videos
          if (processedFile.isVideo) {
            print("Generating thumbnail for video: ${processedFile.path}");
            final thumbPath = await _thumbnailService.generate(
              processedFile.path,
              timeMs: 500, // Reduced time for faster generation
            );
            if (thumbPath != null) {
              print("Thumbnail generated for: ${processedFile.path}");
              processedFile = processedFile.copyWith(thumbnailPath: thumbPath);
            } else {
              print("Failed to generate thumbnail for: ${processedFile.path}");
            }
          }

          // Save to database
          await _database.saveMediaFile(processedFile);
        } catch (e) {
          print("Error processing ${mediaFile.path}: $e");
          // Save basic info even if metadata extraction fails
          await _database.saveMediaFile(mediaFile);
        }
      }));

      // Send partial update
      final updatedMedia = await getCachedMedia();
      _mediaStreamController.add(updatedMedia);

      // Small delay to allow UI to update
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Extract metadata from media file
  Future<MediaFile> _extractMetadata(MediaFile mediaFile) async {
    try {
      if (mediaFile.isVideo) {
        // For videos, extract using video_player
        final controller = VideoPlayerController.file(File(mediaFile.path));
        await controller.initialize();

        final duration = controller.value.duration.inMilliseconds;
        final size = controller.value.size;
        final resolution = '${size.width}x${size.height}';

        await controller.dispose();

        return mediaFile.copyWith(
          title: mediaFile.name,
          duration: duration,
          resolution: resolution,
          scannedAt: DateTime.now(),
        );
      } else {
        // For audio files, we could use a package like 'dart_vlc' or 'audioplayers'
        // For now, we'll just set basic info
        return mediaFile.copyWith(
          title: mediaFile.name,
          scannedAt: DateTime.now(),
        );
      }
    } catch (e) {
      print("Error extracting metadata from ${mediaFile.path}: $e");
      return mediaFile.copyWith(
        title: mediaFile.name,
        scannedAt: DateTime.now(),
      );
    }
  }

  /// Close resources
  Future<void> dispose() async {
    await _database.close();
    await _mediaStreamController.close();
  }
}
