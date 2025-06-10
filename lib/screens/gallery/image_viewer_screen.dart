import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/new_model.dart'; // For RelatedPhoto

class ImageViewerScreen extends StatefulWidget {
  final List<RelatedPhoto> photos;
  final int initialIndex;
  final String? galleryTitle; // To display in AppBar

  const ImageViewerScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
    this.galleryTitle,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showOverlay = true; // To show/hide AppBar and caption

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }

  Future<void> _shareCurrentImage() async {
    if (widget.photos.isNotEmpty && _currentIndex < widget.photos.length) {
      final currentPhoto = widget.photos[_currentIndex];
      // In a real app, you might want to share the image file itself
      // or a link to it if available. For now, sharing the URL and caption.
      String shareText = currentPhoto.photoCaption.isNotEmpty
          ? '${currentPhoto.photoCaption}\n${currentPhoto.photoUrl}'
          : currentPhoto.photoUrl;

      if (widget.galleryTitle != null && widget.galleryTitle!.isNotEmpty) {
        shareText = '${widget.galleryTitle}\n$shareText';
      }

      await Share.share(shareText, subject: 'صورة من معرض الشروق');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto =
        widget.photos.isNotEmpty && _currentIndex < widget.photos.length
            ? widget.photos[_currentIndex]
            : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleOverlay,
        child: Stack(
          children: [
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                final photo = widget.photos[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(photo.photoUrl),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 2.5,
                  heroAttributes: PhotoViewHeroAttributes(
                      tag: 'photo_${photo.photoUrl}_$index'),
                  onTapUp: (context, details, controllerValue) =>
                      _toggleOverlay(),
                );
              },
              itemCount: widget.photos.length,
              loadingBuilder: (context, event) => const Center(
                child: SizedBox(
                  width: 30.0,
                  height: 30.0,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              ),
              pageController: _pageController,
              onPageChanged: _onPageChanged,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),

            // Overlay for AppBar and Caption
            if (_showOverlay) ...[
              // AppBar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppBar(
                  // ignore: deprecated_member_use
                  backgroundColor: Colors.black.withOpacity(0.5),
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  title: Text(
                    widget.galleryTitle ?? 'عارض الصور',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  actions: [
                    IconButton(
                      icon:
                          const Icon(Icons.share_outlined, color: Colors.white),
                      onPressed: _shareCurrentImage,
                      tooltip: 'مشاركة الصورة',
                    ),
                    // Counter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Center(
                        child: Text(
                          '${_currentIndex + 1} / ${widget.photos.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Caption
              if (currentPhoto != null && currentPhoto.photoCaption.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.6),
                    child: Text(
                      currentPhoto.photoCaption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
