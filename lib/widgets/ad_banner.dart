import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform; // To check platform for ad unit IDs

class AdBanner extends StatefulWidget {
  final String adUnit; // The ad unit ID for the banner
  final AdSize adSize; // The size of the banner (e.g., AdSize.banner)
  final bool showPlaceholderOnError; // Whether to show a placeholder if ad fails

  const AdBanner({
    super.key,
    required this.adUnit,
    this.adSize = AdSize.banner, // Default to standard banner size
    this.showPlaceholderOnError = true,
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _adFailedToLoad = false;

  // Ad Unit IDs - Replace with your actual AdMob IDs
  // These are test IDs provided by Google.
  static const String _androidTestAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTestAdUnitId = 'ca-app-pub-3940256099942544/2934735716';

  String get _actualAdUnitId {
    // Use widget.adUnit if it's not a test ID placeholder,
    // otherwise use platform-specific test IDs.
    // In production, you'd likely always use widget.adUnit directly
    // assuming it's correctly configured for production.
    if (widget.adUnit.startsWith('ca-app-pub-')) {
      return widget.adUnit;
    }
    if (Platform.isAndroid) {
      return _androidTestAdUnitId;
    } else if (Platform.isIOS) {
      return _iosTestAdUnitId;
    }
    return widget.adUnit; // Fallback, though should be one of the above
  }


  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _actualAdUnitId,
      request: const AdRequest(), // You can add targeting info here
      size: widget.adSize,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('$BannerAd loaded.');
          setState(() {
            _isAdLoaded = true;
            _adFailedToLoad = false;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('$BannerAd failedToLoad: $error');
          ad.dispose();
          setState(() {
            _isAdLoaded = false;
            _adFailedToLoad = true;
          });
        },
        onAdOpened: (Ad ad) => debugPrint('$BannerAd onAdOpened.'),
        onAdClosed: (Ad ad) => debugPrint('$BannerAd onAdClosed.'),
        onAdImpression: (Ad ad) => debugPrint('$BannerAd onAdImpression.'),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } else if (_adFailedToLoad && widget.showPlaceholderOnError) {
      // Optional: Show a placeholder if the ad fails to load
      return Container(
        alignment: Alignment.center,
        width: widget.adSize.width.toDouble(),
        height: widget.adSize.height.toDouble(),
        color: Colors.grey[200], // Placeholder background
        child: Text(
          'Advertisement', // Placeholder text
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    } else {
      // While loading or if placeholder is disabled on error, show an empty container
      // or a container with the ad's dimensions to prevent layout jumps.
      return SizedBox(
        width: widget.adSize.width.toDouble(),
        height: widget.adSize.height.toDouble(),
      );
    }
  }
}
