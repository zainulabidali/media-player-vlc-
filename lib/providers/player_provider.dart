// FILE: lib/providers/player_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';

class PlayerProvider extends ChangeNotifier {
  // video
  VideoPlayerController? _videoController;
  VideoPlayerController? get videoController => _videoController;

  // audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer get audioPlayer => _audioPlayer;

  bool get isVideoPlaying => _videoController?.value.isPlaying ?? false;
  bool get isAudioPlaying => _audioPlayer.playing;

  Future<void> openVideo(String path) async {
    await disposeVideo();
    _videoController = VideoPlayerController.file(File(path));
    await _videoController!.initialize();
    _videoController!.setLooping(false);
    // Remove auto-play here to let the UI control playback
    // _videoController!.play();
    notifyListeners();
  }

  Future<void> disposeVideo() async {
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }
  }

  Future<void> openAudio(String path) async {
    try {
      await _audioPlayer.setFilePath(path);
      _audioPlayer.play();
      notifyListeners();
    } catch (e) {
      // handle error
    }
  }

  Future<void> toggleVideoPlay() async {
    if (_videoController == null) return;
    // Ensure the controller is initialized before toggling play state
    if (!_videoController!.value.isInitialized) return;

    if (_videoController!.value.isPlaying) {
      await _videoController!.pause();
    } else {
      await _videoController!.play();
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
    notifyListeners();
  }

  Future<void> dispose() async {
    await disposeVideo();
    await _audioPlayer.dispose();
  }
}
