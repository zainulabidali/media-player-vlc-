// FILE: lib/models/media_file.dart
class MediaFile {
  final String path;
  final String name;
  final bool isVideo;
  final int? durationMs;
  final String? thumbnailPath; // local thumbnail cache path

  MediaFile({
    required this.path,
    required this.name,
    required this.isVideo,
    this.durationMs,
    this.thumbnailPath,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'isVideo': isVideo,
        'durationMs': durationMs,
        'thumbnailPath': thumbnailPath,
      };

  factory MediaFile.fromJson(Map<String, dynamic> json) => MediaFile(
        path: json['path'],
        name: json['name'],
        isVideo: json['isVideo'],
        durationMs: json['durationMs'],
        thumbnailPath: json['thumbnailPath'],
      );
}
