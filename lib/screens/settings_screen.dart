// FILE: lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:hive/hive.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = false;
  bool autoSelectAudioTracks = true;
  String preferredAudioLanguage = 'original';

  @override
  void initState() {
    super.initState();
    // load settings from Hive (not required to exist)
    try {
      final box = Hive.box('settings');
      notifications = box.get('notifications', defaultValue: false);
      autoSelectAudioTracks =
          box.get('autoSelectAudioTracks', defaultValue: true);
      preferredAudioLanguage =
          box.get('preferredAudioLanguage', defaultValue: 'original');
    } catch (e) {}
  }

  void _toggleNotifs(bool v) {
    setState(() => notifications = v);
    try {
      final box = Hive.isBoxOpen('settings')
          ? Hive.box('settings')
          : Hive.openBox('settings') as Box;
      box.put('notifications', v);
    } catch (e) {}
  }

  void _toggleAutoSelectAudio(bool v) {
    setState(() => autoSelectAudioTracks = v);
    try {
      final box = Hive.isBoxOpen('settings')
          ? Hive.box('settings')
          : Hive.openBox('settings') as Box;
      box.put('autoSelectAudioTracks', v);
    } catch (e) {}
  }

  void _setPreferredAudioLanguage(String lang) {
    setState(() => preferredAudioLanguage = lang);
    try {
      final box = Hive.isBoxOpen('settings')
          ? Hive.box('settings')
          : Hive.openBox('settings') as Box;
      box.put('preferredAudioLanguage', lang);
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
              style: const TextStyle(color: Colors.white70)),
          onTap: () => _showLanguageSelector(),
        ),
        ListTile(
          title: const Text('Theme', style: TextStyle(color: AppColors.text)),
          subtitle: const Text('Dark (fixed)',
              style: TextStyle(color: Colors.white70)),
        ),
        const Divider(),
        const ListTile(
          title: Text('About', style: TextStyle(color: AppColors.text)),
          subtitle: Text('VLC-style sample player',
              style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  void _showLanguageSelector() {
    final languages = {
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
    };
    return languageMap[code] ?? code;
  }
}
