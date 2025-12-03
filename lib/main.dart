// FILE: lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/media_provider.dart';
import 'providers/player_provider.dart';
import 'services/audio_service.dart';
import 'services/enhanced_media_scanner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Initialize the enhanced media scanner
  final scanner = EnhancedMediaScanner();
  await scanner.init();

  // Initialize the audio service
  final audioService = AudioService();
  await audioService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MediaProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider.value(value: audioService),
      ],
      child: const MyApp(),
    ),
  );
}
