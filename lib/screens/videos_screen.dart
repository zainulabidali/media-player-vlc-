// FILE: lib/screens/videos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';
import '../widgets/media_tile.dart';
import '../providers/player_provider.dart';
import 'player_screen.dart';
import '../constants.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});
  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {

  @override
  void initState() {
    super.initState();

    // FIX: scan() should not be called directly inside initState().
    // Use post-frame callback to avoid "setState during build" error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mp = Provider.of<MediaProvider>(context, listen: false);
      mp.scan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mp, _) {
        if (mp.loading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final videos = mp.videos;

        if (videos.isEmpty) {
          return const Center(
            child: Text(
              'No videos found',
              style: TextStyle(color: AppColors.text),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(Sizes.padding),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 13 / 9,
              crossAxisSpacing: 5,
              mainAxisSpacing: 20,
            ),
            itemCount: videos.length,
            itemBuilder: (context, i) {
              final m = videos[i];
              return MediaTile(
                media: m,
                onTap: () {
                  Provider.of<PlayerProvider>(context, listen: false)
                      .openVideo(m.path);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PlayerScreen(),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
