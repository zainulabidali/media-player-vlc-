// FILE: README.md

# VLC-Style Media Player (Flutter sample)

## Overview
This is a sample Flutter project that implements a VLC-style media player UI with:
- Bottom navigation (Videos, Audio, Files, Settings)
- Local media scanning (videos + audio)
- Video playback using `video_player`
- Audio playback using `just_audio`
- State management via `provider`
- Thumbnail generation using `video_thumbnail`
- Local persistence scaffolding using `hive`

## How to run
1. Ensure Flutter SDK installed (stable channel).
2. Add sample media files to `assets/sample_media/` or grant device storage permission to scan.
3. `flutter pub get`
4. For Android, ensure manifest has storage permissions; see notes below.
5. Connect a device/emulator with media files and run:
