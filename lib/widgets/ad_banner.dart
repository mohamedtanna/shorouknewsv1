import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'dart:io' show Platform; // To check platform for ad unit IDs

class AdBanner extends StatelessWidget {
  final String adUnit; // Unused when ads are disabled
  final dynamic adSize;
  final bool showPlaceholderOnError;

  const AdBanner({
    super.key,
    required this.adUnit,
    this.adSize,
    this.showPlaceholderOnError = true,
  });

  @override
  Widget build(BuildContext context) {
    // Ads are disabled; return an empty widget
    return const SizedBox.shrink();
  }
}
