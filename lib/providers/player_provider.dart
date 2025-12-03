// FILE: lib/providers/player_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hive/hive.dart';

class PlayerProvider extends ChangeNotifier {
  // video
  VideoPlayerController? _videoController;
  VideoPlayerController? get videoController => _videoController;

  // audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer get audioPlayer => _audioPlayer;

  // Multiple audio tracks support
  List<AudioTrackInfo> _availableAudioTracks = [];
  int _selectedAudioTrackIndex = 0;

  List<AudioTrackInfo> get availableAudioTracks => _availableAudioTracks;
  int get selectedAudioTrackIndex => _selectedAudioTrackIndex;

  bool get isVideoPlaying => _videoController?.value.isPlaying ?? false;
  bool get isAudioPlaying => _audioPlayer.playing;

  Future<void> openVideo(String path) async {
    await disposeVideo();

    try {
      // Create controller with progressive loading
      _videoController = VideoPlayerController.file(File(path));

      // Initialize with minimal data for quick loading
      await _videoController!.initialize();
      _videoController!.setLooping(false);

      // Initialize audio tracks for this video
      _initializeAudioTracks(path);

      notifyListeners();
    } catch (e) {
      print("Error opening video: $e");
      await disposeVideo();
    }
  }

  // Initialize audio tracks for a video file
  void _initializeAudioTracks(String videoPath) {
    _availableAudioTracks = [];
    _selectedAudioTrackIndex = 0;

    try {
      // Add a default "original" track for the video's embedded audio
      _availableAudioTracks.add(AudioTrackInfo(
        path: '', // Empty path means use video's original audio
        language: 'Original (Embedded)',
        languageCode: 'original',
      ));

      // Look for common external audio file patterns alongside the video
      final baseName = videoPath.substring(0, videoPath.lastIndexOf('.'));
      final audioExtensions = ['.mp3', '.m4a', '.aac', '.flac', '.wav', '.ogg'];
      final languageCodes = [
        'en',
        'es',
        'fr',
        'de',
        'it',
        'pt',
        'ru',
        'zh',
        'ja',
        'ko'
      ];

      // Check for audio files with language codes
      for (final lang in languageCodes) {
        for (final ext in audioExtensions) {
          final audioPath = '${baseName}_$lang$ext';
          if (File(audioPath).existsSync()) {
            _availableAudioTracks.add(AudioTrackInfo(
              path: audioPath,
              language: '${_getLanguageName(lang)} Audio',
              languageCode: lang,
            ));
          }
        }
      }

      // Check for generic numbered audio tracks
      for (int i = 1; i <= 5; i++) {
        for (final ext in audioExtensions) {
          final audioPath = '${baseName}_$i$ext';
          if (File(audioPath).existsSync()) {
            _availableAudioTracks.add(AudioTrackInfo(
              path: audioPath,
              language: 'Alternative Audio $i',
              languageCode: 'alt$i',
            ));
          }
        }
      }

      // Also check for audio files with common naming patterns
      final commonPatterns = ['audio', 'sound', 'music'];
      for (final pattern in commonPatterns) {
        for (final ext in audioExtensions) {
          final audioPath = '${baseName}_$pattern$ext';
          if (File(audioPath).existsSync()) {
            _availableAudioTracks.add(AudioTrackInfo(
              path: audioPath,
              language: '${pattern.capitalize()} Track',
              languageCode: pattern,
            ));
          }
        }
      }

      // Auto-select preferred audio track based on settings
      _autoSelectPreferredAudioTrack();
    } catch (e) {
      print('Error initializing audio tracks: $e');
      // Always ensure we have at least the original track
      if (_availableAudioTracks.isEmpty) {
        _availableAudioTracks.add(AudioTrackInfo(
          path: '',
          language: 'Original',
          languageCode: 'original',
        ));
      }
    }
  }

  String _getLanguageName(String code) {
    final languageMap = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'zh': 'Chinese',
      'ja': 'Japanese',
      'ko': 'Korean',
    };
    return languageMap[code] ?? code;
  }

  Future<void> selectAudioTrack(int index) async {
    if (index < 0 || index >= _availableAudioTracks.length) return;

    _selectedAudioTrackIndex = index;
    notifyListeners(); // Notify early to update UI

    // If selecting original track, pause external audio player
    if (index == 0) {
      await _audioPlayer.pause();
    } else {
      // Load and play the selected audio track with progressive loading
      final track = _availableAudioTracks[index];
      if (track.path.isNotEmpty) {
        try {
          // Set the audio source with buffering for progressive loading
          await _audioPlayer.setFilePath(track.path);

          // Sync the audio with video position
          if (_videoController != null) {
            await _audioPlayer.seek(_videoController!.value.position);
          }

          // Start playing if video is playing
          if (_videoController != null && _videoController!.value.isPlaying) {
            await _audioPlayer.play();
          }
        } catch (e) {
          print('Error loading audio track: $e');
          // Revert to original track on error
          _selectedAudioTrackIndex = 0;
          notifyListeners();
        }
      }
    }
  }

  // Auto-select preferred audio track based on user settings
  void _autoSelectPreferredAudioTrack() {
    try {
      // Load settings
      bool autoSelect = true;
      String preferredLang = 'original';

      if (Hive.isBoxOpen('settings')) {
        final box = Hive.box('settings');
        autoSelect = box.get('autoSelectAudioTracks', defaultValue: true);
        preferredLang =
            box.get('preferredAudioLanguage', defaultValue: 'original');
      }

      if (!autoSelect ||
          preferredLang == 'original' ||
          _availableAudioTracks.length <= 1) {
        return; // Keep original track selected
      }

      // Look for a track matching the preferred language
      for (int i = 1; i < _availableAudioTracks.length; i++) {
        if (_availableAudioTracks[i].languageCode == preferredLang) {
          _selectedAudioTrackIndex = i;
          // Load the preferred track
          // Note: We don't call selectAudioTrack here to avoid recursive issues
          break;
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error auto-selecting audio track: $e');
    }
  }

  Future<void> disposeVideo() async {
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }

    // Reset audio tracks
    _availableAudioTracks = [];
    _selectedAudioTrackIndex = 0;
  }

  Future<void> openAudio(String path) async {
    try {
      // Open audio with progressive loading
      await _audioPlayer.setFilePath(path);
      await _audioPlayer.play();
      notifyListeners();
    } catch (e) {
      print("Error opening audio: $e");
    }
  }

  Future<void> toggleVideoPlay() async {
    if (_videoController == null) return;
    // Ensure the controller is initialized before toggling play state
    if (!_videoController!.value.isInitialized) return;

    if (_videoController!.value.isPlaying) {
      await _videoController!.pause();
      // Also pause external audio if playing
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      }
    } else {
      await _videoController!.play();
      // Resume external audio if a track is selected
      if (_selectedAudioTrackIndex > 0 && _availableAudioTracks.isNotEmpty) {
        // Sync the audio with video position
        await _audioPlayer.seek(_videoController!.value.position);
        await _audioPlayer.play();
      }
    }
    notifyListeners();
  }

  Future<void> toggleAudioPlay() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
    notifyListeners();
  }

  Future<void> stopAudio() async {
    await _audioPlayer.pause();
    await _audioPlayer.seek(Duration.zero);
    notifyListeners();
  }

  Future<void> seekVideo(Duration pos) async {
    if (_videoController == null) return;
    await _videoController!.seekTo(pos);

    // Also seek the audio track if one is selected
    if (_selectedAudioTrackIndex > 0 && _availableAudioTracks.isNotEmpty) {
      await _audioPlayer.seek(pos);
    }

    notifyListeners();
  }

  Future<void> dispose() async {
    await disposeVideo();
    await _audioPlayer.dispose();
  }
}

class AudioTrackInfo {
  final String path;
  final String language;
  final String languageCode;

  AudioTrackInfo({
    required this.path,
    required this.language,
    required this.languageCode,
  });
}

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
