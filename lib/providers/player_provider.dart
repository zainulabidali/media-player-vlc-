// FILE: lib/providers/player_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hive/hive.dart';

class PlayerProvider extends ChangeNotifier {
  // media_kit video
  late Player _player;
  late VideoController _videoController;
  Player get player => _player;
  VideoController get videoController => _videoController;

  // audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer get audioPlayer => _audioPlayer;

  // Audio and subtitle tracks from media_kit
  List<AudioTrack> _availableAudioTracks = [];
  List<SubtitleTrack> _availableSubtitleTracks = [];
  int _selectedAudioTrackIndex = 0;
  int _selectedSubtitleTrackIndex = -1; // -1 means no subtitle selected

  List<AudioTrack> get availableAudioTracks => _availableAudioTracks;
  List<SubtitleTrack> get availableSubtitleTracks => _availableSubtitleTracks;
  int get selectedAudioTrackIndex => _selectedAudioTrackIndex;
  int get selectedSubtitleTrackIndex => _selectedSubtitleTrackIndex;

  bool get isVideoPlaying => _player.state.playing;
  bool get isAudioPlaying => _audioPlayer.playing;

  PlayerProvider() {
    _player = Player();
    _videoController = VideoController(_player);
    _setupTrackListeners();
  }

  void _setupTrackListeners() {
    // Listen for track changes from media_kit
    _player.stream.tracks.listen((tracks) {
      _availableAudioTracks = tracks.audio;
      _availableSubtitleTracks = tracks.subtitle;
      notifyListeners();
    });
  }

  Future<void> openVideo(String path) async {
    await disposeVideo();

    try {
      // Open video with media_kit
      await _player.open(Media(path));

      // Auto-select first audio track if available
      if (_availableAudioTracks.isNotEmpty) {
        _selectedAudioTrackIndex = 0;
      }

      notifyListeners();
    } catch (e) {
      print("Error opening video: $e");
      await disposeVideo();
    }
  }

  Future<void> selectAudioTrack(int index) async {
    if (index < 0 || index >= _availableAudioTracks.length) return;

    try {
      await _player.setAudioTrack(_availableAudioTracks[index]);
      _selectedAudioTrackIndex = index;
      notifyListeners();
    } catch (e) {
      print('Error selecting audio track: $e');
    }
  }

  Future<void> selectSubtitleTrack(int index) async {
    try {
      if (index == -1) {
        // Disable subtitles
        await _player.setSubtitleTrack(SubtitleTrack.no());
      } else if (index >= 0 && index < _availableSubtitleTracks.length) {
        // Enable subtitle track
        await _player.setSubtitleTrack(_availableSubtitleTracks[index]);
        _selectedSubtitleTrackIndex = index;
      }
      notifyListeners();
    } catch (e) {
      print('Error selecting subtitle track: $e');
    }
  }

  Future<void> disposeVideo() async {
    // Reset tracks
    _availableAudioTracks = [];
    _availableSubtitleTracks = [];
    _selectedAudioTrackIndex = 0;
    _selectedSubtitleTrackIndex = -1;
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
    if (_player.state.playing) {
      await _player.pause();
    } else {
      await _player.play();
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
    await _player.seek(pos);
    notifyListeners();
  }

  Future<void> dispose() async {
    await disposeVideo();
    await _audioPlayer.dispose();
    await _player.dispose();
  }
}
