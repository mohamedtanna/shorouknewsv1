import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme.dart';
import '../../widgets/section_app_bar.dart';

class VideoDetailScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;

  const VideoDetailScreen({
    super.key,
    required this.videoUrl,
    required this.videoTitle, required String videoId,
  });

  @override
  _VideoDetailScreenState createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late VideoPlayerController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isLoading = false;
        });
        _controller.play();
      }).catchError((error) {
        setState(() {
          _isLoading = false;
        });
        // Handle initialization errors
        print('Error initializing video player: $error');
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SectionAppBar(
        title: Text(widget.videoTitle),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
              )
            : _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : Text(
                    'Error loading video.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        backgroundColor: AppTheme.tertiaryColor,
        foregroundColor: Colors.white,
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
