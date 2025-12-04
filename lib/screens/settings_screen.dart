// FILE: lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = false;
  bool autoSelectAudioTracks = true;
  String preferredAudioLanguage = 'original';
  String currentTheme = 'dark'; // 'light' or 'dark'
  String appVersion = '1.0.0';
  String buildNumber = '1';
  String videoQuality = 'auto'; // 'auto', 'low', 'medium', 'high'
  bool enableCache = true;
  String cacheSize = '0 MB';

  @override
  void initState() {
    super.initState();
    // load settings from Hive (not required to exist)
    _loadSettings();

    // Get app version info
    _getAppInfo();

    // Calculate cache size
    _calculateCacheSize();
  }

  void _loadSettings() async {
    try {
      final box = Hive.isBoxOpen('settings')
          ? Hive.box('settings')
          : await Hive.openBox('settings');
      notifications = box.get('notifications', defaultValue: false);
      autoSelectAudioTracks =
          box.get('autoSelectAudioTracks', defaultValue: true);
      preferredAudioLanguage =
          box.get('preferredAudioLanguage', defaultValue: 'original');
      currentTheme = box.get('theme', defaultValue: 'dark');
      videoQuality = box.get('videoQuality', defaultValue: 'auto');
      enableCache = box.get('enableCache', defaultValue: true);
    } catch (e) {
      // Handle error silently
    }
  }

  void _getAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        appVersion = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/thumbnails');

      if (await cacheDir.exists()) {
        int size = 0;
        await for (FileSystemEntity entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            size += await entity.length();
          }
        }

        setState(() {
          cacheSize = '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
        });
      } else {
        setState(() {
          cacheSize = '0 MB';
        });
      }
    } catch (e) {
      setState(() {
        cacheSize = 'Unknown';
      });
    }
  }

  void _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/thumbnails');

      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();

        setState(() {
          cacheSize = '0 MB';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cache cleared successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to clear cache')),
        );
      }
    }
  }

  void _toggleNotifs(bool v) async {
    setState(() => notifications = v);
    try {
      final box = Hive.isBoxOpen('settings')
          ? Hive.box('settings')
          : await Hive.openBox('settings');
      box.put('notifications', v);
    } catch (e) {}
  }

  void _toggleAutoSelectAudio(bool v) async {
    setState(() => autoSelectAudioTracks = v);
    try {
      final box = Hive.isBoxOpen('settings')
          ? Hive.box('settings')
          : await Hive.openBox('settings');
      box.put('autoSelectAudioTracks', v);
    } catch (e) {}
  }

  void _setPreferredAudioLanguage(String lang) async {
    setState(() => preferredAudioLanguage = lang);
    try {
      final box = Hive.isBoxOpen('settings')
          ? Hive.box('settings')
          : await Hive.openBox('settings');
      box.put('preferredAudioLanguage', lang);
    } catch (e) {}
  }

  void _setTheme(String theme) async {
    setState(() => currentTheme = theme);
    try {
      final box = Hive.isBoxOpen('settings')
          ? Hive.box('settings')
          : await Hive.openBox('settings');
      box.put('theme', theme);

      // Send event to rebuild app with new theme
      final eventBox = Hive.isBoxOpen('events')
          ? Hive.box('events')
          : await Hive.openBox('events');
      eventBox.put('themeChanged', theme);
    } catch (e) {}
  }

  void _setVideoQuality(String quality) async {
    setState(() => videoQuality = quality);
    try {
      final box = Hive.isBoxOpen('settings')
          ? Hive.box('settings')
          : await Hive.openBox('settings');
      box.put('videoQuality', quality);
    } catch (e) {}
  }

  void _toggleCache(bool v) async {
    setState(() => enableCache = v);
    try {
      final box = Hive.isBoxOpen('settings')
          ? Hive.box('settings')
          : await Hive.openBox('settings');
      box.put('enableCache', v);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ListTile(
          title: const Text('Notifications',
              style: TextStyle(color: AppColors.text)),
          trailing: Switch(
              value: notifications,
              onChanged: _toggleNotifs,
              activeColor: AppColors.accent),
        ),
        ListTile(
          title: const Text('Auto-select Audio Tracks',
              style: TextStyle(color: AppColors.text)),
          subtitle: const Text('Automatically select preferred audio track',
              style: TextStyle(color: Colors.white70)),
          trailing: Switch(
              value: autoSelectAudioTracks,
              onChanged: _toggleAutoSelectAudio,
              activeColor: AppColors.accent),
        ),
        ListTile(
          title: const Text('Preferred Audio Language',
              style: TextStyle(color: AppColors.text)),
          subtitle: Text(_getLanguageName(preferredAudioLanguage),
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis),
          onTap: () => _showLanguageSelector(),
        ),
        ListTile(
          title: const Text('Theme', style: TextStyle(color: AppColors.text)),
          subtitle: Text(_getThemeName(currentTheme),
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis),
          onTap: () => _showThemeSelector(),
        ),
        ListTile(
          title: const Text('Video Quality',
              style: TextStyle(color: AppColors.text)),
          subtitle: Text(_getVideoQualityName(videoQuality),
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis),
          onTap: () => _showVideoQualitySelector(),
        ),
        ListTile(
          title: const Text('Enable Cache',
              style: TextStyle(color: AppColors.text)),
          subtitle: const Text('Cache thumbnails and media data',
              style: TextStyle(color: Colors.white70)),
          trailing: Switch(
              value: enableCache,
              onChanged: _toggleCache,
              activeColor: AppColors.accent),
        ),
        ListTile(
          title: const Text('Clear Cache',
              style: TextStyle(color: AppColors.text)),
          subtitle: Text('Current size: $cacheSize',
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis),
          onTap: _clearCache,
        ),
        const Divider(),
        ExpansionTile(
          title: const Text('About', style: TextStyle(color: AppColors.text)),
          subtitle: const Text('App information and version',
              style: TextStyle(color: Colors.white70)),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('JK Wave Media Player',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text)),
                  const SizedBox(height: 8),
                  const Text(
                      'A feature-rich media player application built with Flutter.',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  Text('Version: $appVersion ($buildNumber)',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  const Text('Developed with Flutter',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showLanguageSelector() {
    final languages = {
      'original': 'Original (Embedded)',
      'en': 'English',
      'zh': 'Chinese',
      'ko': 'Korean',
      'ar': 'Arabic',
      'hi': 'Hindi',
    };

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Preferred Language',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...languages.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.value),
                  value: entry.key,
                  groupValue: preferredAudioLanguage,
                  onChanged: (value) {
                    if (value != null) {
                      _setPreferredAudioLanguage(value);
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showThemeSelector() {
    final themes = {
      'light': 'Light',
      'dark': 'Dark',
    };

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Theme',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...themes.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.value),
                  value: entry.key,
                  groupValue: currentTheme,
                  onChanged: (value) {
                    if (value != null) {
                      _setTheme(value);
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showVideoQualitySelector() {
    final qualities = {
      'auto': 'Auto',
      'low': 'Low (480p)',
      'medium': 'Medium (720p)',
      'high': 'High (1080p)',
    };

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Video Quality',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...qualities.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.value),
                  value: entry.key,
                  groupValue: videoQuality,
                  onChanged: (value) {
                    if (value != null) {
                      _setVideoQuality(value);
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  String _getLanguageName(String code) {
    final languageMap = {
      'original': 'Original (Embedded)',
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
      'ar': 'Arabic',
      'hi': 'Hindi',
      'bn': 'Bengali',
      'ur': 'Urdu',
    };
    return languageMap[code] ?? code;
  }

  String _getThemeName(String theme) {
    final themeMap = {
      'light': 'Light Mode',
      'dark': 'Dark Mode',
    };
    return themeMap[theme] ?? 'Dark Mode';
  }

  String _getVideoQualityName(String quality) {
    final qualityMap = {
      'auto': 'Auto',
      'low': 'Low (480p)',
      'medium': 'Medium (720p)',
      'high': 'High (1080p)',
    };
    return qualityMap[quality] ?? 'Auto';
  }
}
