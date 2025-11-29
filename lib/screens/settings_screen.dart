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

  @override
  void initState() {
    super.initState();
    // load settings from Hive (not required to exist)
    try {
      final box = Hive.box('settings');
      notifications = box.get('notifications', defaultValue: false);
    } catch (e) {}
  }

  void _toggleNotifs(bool v) {
    setState(() => notifications = v);
    try {
      final box = Hive.isBoxOpen('settings') ? Hive.box('settings') : Hive.openBox('settings') as Box;
      box.put('notifications', v);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ListTile(
          title: const Text('Notifications', style: TextStyle(color: AppColors.text)),
          trailing: Switch(value: notifications, onChanged: _toggleNotifs, activeColor: AppColors.accent),
        ),
        ListTile(
          title: const Text('Theme', style: TextStyle(color: AppColors.text)),
          subtitle: const Text('Dark (fixed)', style: TextStyle(color: Colors.white70)),
        ),
        const Divider(),
        const ListTile(
          title: Text('About', style: TextStyle(color: AppColors.text)),
          subtitle: Text('VLC-style sample player', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
