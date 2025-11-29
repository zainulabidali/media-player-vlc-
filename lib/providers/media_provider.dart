// FILE: lib/providers/media_provider.dart
import 'package:flutter/foundation.dart';
import '../models/media_file.dart';
import '../services/media_service.dart';
import '../services/thumbnail_service.dart';

class MediaProvider extends ChangeNotifier {
  final MediaService _service = MediaService();
  final ThumbnailService _thumbService = ThumbnailService();

  List<MediaFile> _videos = [];
  List<MediaFile> _audios = [];
  bool _loading = false;

  List<MediaFile> get videos => _videos;
  List<MediaFile> get audios => _audios;
  bool get loading => _loading;

  Future<void> scan() async {
    _loading = true;
    notifyListeners();
    final list = await _service.scanDeviceForMedia();
    final vids = <MediaFile>[];
    final auds = <MediaFile>[];
    for (final m in list) {
      if (m.isVideo) {
        // generate thumbnail (best-effort)
        final thumb = await _thumbService.generate(m.path);
        vids.add(MediaFile(
          path: m.path,
          name: m.name,
          isVideo: true,
          thumbnailPath: thumb,
        ));
      } else {
        auds.add(m);
      }
    }
    _videos = vids;
    _audios = auds;
    _loading = false;
    notifyListeners();
  }
}
