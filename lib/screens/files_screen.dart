// FILE: lib/screens/files_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../constants.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import 'player_screen.dart';

class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path!;
      // determine type naive
      final ext = path.split('.').last.toLowerCase();
      final isVideo = ['mp4', 'mkv', 'webm', 'avi'].contains(ext);
      if (isVideo) {
        Provider.of<PlayerProvider>(context, listen: false).openVideo(path);
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
      } else {
        Provider.of<PlayerProvider>(context, listen: false).openAudio(path);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playing file')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.folder_open),
        label: const Text('Pick file'),
        onPressed: () => _pickFile(context),
      ),
    );
  }
}
