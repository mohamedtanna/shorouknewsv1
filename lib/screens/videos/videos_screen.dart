import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/section_app_bar.dart';

class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SectionAppBar(
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
