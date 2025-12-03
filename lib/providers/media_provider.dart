// FILE: lib/providers/media_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/media_file.dart';
import '../services/enhanced_media_scanner.dart';

class MediaProvider extends ChangeNotifier {
  final EnhancedMediaScanner _scanner = EnhancedMediaScanner();

  List<MediaFile> _videos = [];
  List<MediaFile> _audios = [];
  bool _loading = false;

  List<MediaFile> get videos => _videos;
  List<MediaFile> get audios => _audios;
  bool get loading => _loading;

  MediaProvider() {
    _init();
  }

  Future<void> _init() async {
    await _scanner.init();

    // Listen to media updates
    _scanner.mediaStream.listen((mediaFiles) {
      _updateMediaLists(mediaFiles);
    });
  }

  void _updateMediaLists(List<MediaFile> mediaFiles) {
    final vids = <MediaFile>[];
    final auds = <MediaFile>[];

    for (final media in mediaFiles) {
      if (media.isVideo) {
        vids.add(media);
      } else {
        auds.add(media);
      }
    }

    _videos = vids;
    _audios = auds;
    _loading = _scanner.isScanning;

    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> scan({bool forceRescan = false}) async {
    await _scanner.scanMedia(forceRescan: forceRescan);
  }

  Future<void> dispose() async {
    await _scanner.dispose();
    super.dispose();
  }
}
