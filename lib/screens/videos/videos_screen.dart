import 'package:flutter/material.dart';

import '../../core/theme.dart';

class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
      ),
      body: Center(
        child: Text(
          'Video Listing Page',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
              ),
        ),
      ),
    );
  }
}
