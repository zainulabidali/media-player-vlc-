// FILE: lib/services/audio_service.dart
import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import '../models/media_file.dart';

class AudioService with ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  List<MediaFile> _queue = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isLooping = false;
  bool _isShuffling = false;
  double _playbackSpeed = 1.0;

  // Streams for audio state
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<bool> get playingStream => _audioPlayer.playingStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  List<MediaFile> get queue => _queue;
  int get currentIndex => _currentIndex;
  MediaFile? get currentMedia => _queue.isEmpty ? null : _queue[_currentIndex];
  bool get isPlaying => _isPlaying;
  bool get isLooping => _isLooping;
  bool get isShuffling => _isShuffling;
  double get playbackSpeed => _playbackSpeed;
  Duration get position => _audioPlayer.position;
  Duration? get duration => _audioPlayer.duration;

  // Initialize the audio service
  Future<void> init() async {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    // Listen to completion events
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handlePlaybackCompleted();
      }
    });
  }

  // Set the current queue and play a specific track
  Future<void> setQueue(List<MediaFile> queue, {int startIndex = 0}) async {
    _queue = List.from(queue);
    _currentIndex = startIndex;

    if (_queue.isNotEmpty) {
      await playTrackAtIndex(_currentIndex);
    }

    notifyListeners();
  }

  // Play a specific audio file
  Future<void> playAudio(MediaFile mediaFile) async {
    // Create a single-item queue
    _queue = [mediaFile];
    _currentIndex = 0;

    await playTrackAtIndex(0);
    notifyListeners();
  }

  // Public method to play a specific track from the queue
  Future<void> playTrackAtIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;

    try {
      final mediaFile = _queue[index];
      await _audioPlayer.setFilePath(mediaFile.path);
      await _audioPlayer.setSpeed(_playbackSpeed);
      await _audioPlayer.play();
      _currentIndex = index;
    } catch (e) {
      print('Error loading audio track: $e');
    }
  }

  // Play or pause the current track
  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      if (_queue.isNotEmpty) {
        await _audioPlayer.play();
      }
    }
    notifyListeners();
  }

  // Stop playback
  Future<void> stop() async {
    await _audioPlayer.stop();
    notifyListeners();
  }

  // Seek to a specific position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // Skip to next track
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;

    int nextIndex;
    if (_isShuffling) {
      nextIndex = _randomIndex();
    } else {
      nextIndex = (_currentIndex + 1) % _queue.length;
    }

    await playTrackAtIndex(nextIndex);
    notifyListeners();
  }

  // Skip to previous track
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;

    int prevIndex;
    if (_isShuffling) {
      prevIndex = _randomIndex();
    } else {
      prevIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    }

    await playTrackAtIndex(prevIndex);
    notifyListeners();
  }

  // Toggle looping
  void toggleLooping() {
    _isLooping = !_isLooping;
    _audioPlayer.setLoopMode(_isLooping ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  // Toggle shuffling
  void toggleShuffling() {
    _isShuffling = !_isShuffling;
    notifyListeners();
  }

  // Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _audioPlayer.setSpeed(speed);
    notifyListeners();
  }

  // Handle playback completion
  void _handlePlaybackCompleted() {
    if (_isLooping) {
      // Replay the same track
      playTrackAtIndex(_currentIndex);
    } else if (_currentIndex < _queue.length - 1) {
      // Play next track
      skipToNext();
    } else {
      // End of queue
      _isPlaying = false;
      notifyListeners();
    }
  }

  // Generate a random index for shuffling
  int _randomIndex() {
    if (_queue.length <= 1) return 0;
    int newIndex;
    do {
      newIndex = Random().nextInt(_queue.length);
    } while (newIndex == _currentIndex && _queue.length > 1);
    return newIndex;
  }

  // Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
