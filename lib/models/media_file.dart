// FILE: lib/models/media_file.dart
class MediaFile {
  final String path;
  final String name;
  final bool isVideo;
  final String? thumbnailPath;
  final String? title;
  final int? duration; // in milliseconds
  final int? size; // in bytes
  final DateTime? lastModified;
  final String? resolution;
  final String? codec;
  final DateTime? scannedAt;

  MediaFile({
    required this.path,
    required this.name,
    required this.isVideo,
    this.thumbnailPath,
    this.title,
    this.duration,
    this.size,
    this.lastModified,
    this.resolution,
    this.codec,
    this.scannedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaFile &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;

  MediaFile copyWith({
    String? path,
    String? name,
    bool? isVideo,
    String? thumbnailPath,
    String? title,
    int? duration,
    int? size,
    DateTime? lastModified,
    String? resolution,
    String? codec,
    DateTime? scannedAt,
  }) {
    return MediaFile(
      path: path ?? this.path,
      name: name ?? this.name,
      isVideo: isVideo ?? this.isVideo,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
      resolution: resolution ?? this.resolution,
      codec: codec ?? this.codec,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'isVideo': isVideo,
      'thumbnailPath': thumbnailPath,
      'title': title,
      'duration': duration,
      'size': size,
      'lastModified': lastModified?.millisecondsSinceEpoch,
      'resolution': resolution,
      'codec': codec,
      'scannedAt': scannedAt?.millisecondsSinceEpoch,
    };
  }

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      path: json['path'],
      name: json['name'],
      isVideo: json['isVideo'],
      thumbnailPath: json['thumbnailPath'],
      title: json['title'],
      duration: json['duration'],
      size: json['size'],
      lastModified: json['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastModified'])
          : null,
      resolution: json['resolution'],
      codec: json['codec'],
      scannedAt: json['scannedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['scannedAt'])
          : null,
    );
  }
}
