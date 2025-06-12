import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/new_model.dart'; // For RelatedPhoto
import '../../core/theme.dart';
// import '../../widgets/ad_banner.dart';
import 'gallery_module.dart'; // For GalleryAlbum if you use it
// Import ImageViewerScreen if you navigate directly, or rely on router
// import 'image_viewer_screen.dart';

class PhotoGalleryScreen extends StatefulWidget {
  // Option 1: Pass a list of photos directly (e.g., from a news article)
  final List<RelatedPhoto>? photos;
  // Option 2: Pass an album ID to fetch photos for that album
  final String? albumId;
  final String? galleryTitle; // Optional title for the AppBar

  const PhotoGalleryScreen({
    super.key,
    this.photos,
    this.albumId,
    this.galleryTitle = 'معرض الصور',
  });

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<RelatedPhoto> _displayPhotos = [];
  bool _isLoading = true;
  String? _error;
  final GalleryModule _galleryModule = GalleryModule();

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (widget.photos != null) {
        _displayPhotos = widget.photos!;
      } else if (widget.albumId != null) {
        // Fetch photos for the album
        final album = await _galleryModule.fetchAlbumDetails(widget.albumId!);
        _displayPhotos = album.photos;
      } else {
        // Default: Fetch general gallery albums and pick the first one's photos
        // Or, you might want to show a list of albums first.
        // For this example, let's fetch some general photos if no specific data is passed.
        final albums = await _galleryModule.fetchGalleryAlbums(pageSize: 1);
        if (albums.isNotEmpty) {
          _displayPhotos = albums.first.photos;
        } else {
          _displayPhotos = [];
        }
      }
    } catch (e) {
      _error = 'فشل تحميل الصور: ${e.toString()}';
      debugPrint('Error loading photos: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToImageViewer(int initialIndex) {
    // Pass the list of photos and the initial index to the ImageViewerScreen
    // Ensure ImageViewerScreen is set up to receive these parameters via GoRouter
    // For simplicity, storing in a temporary provider or passing as extra
    // A better way would be a dedicated GalleryProvider or passing via path/query params if feasible.

    // Using GoRouter's 'extra' parameter to pass complex data
    context.goNamed(
      'image-viewer',
      extra: {
        'photos': _displayPhotos,
        'initialIndex': initialIndex,
        'galleryTitle': widget.galleryTitle,
      },
      // If image-viewer takes path params for individual images (less ideal for a list):
      // pathParameters: {'photoId': _displayPhotos[initialIndex].id_if_available},
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.tertiaryColor, width: 4),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/home'),
            child: const Text(
              'الرئيسية',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const Text(' > ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            widget.galleryTitle ?? 'معرض الصور',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _galleryModule.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.galleryTitle ?? 'معرض الصور'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home'); // Fallback to home
            }
          },
        ),
      ),
        body: Column(
          children: [
          // const AdBanner(adUnit: '/21765378867/ShorouknewsApp_LeaderBoard2'),
          _buildBreadcrumb(),
          Expanded(
            child: _isLoading
                ? _buildLoadingShimmer()
                : _error != null
                    ? _buildErrorWidget()
                    : _displayPhotos.isEmpty
                        ? _buildEmptyState()
                        : _buildPhotoGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 1.0, // Square items
      ),
      itemCount: 9, // Number of shimmer placeholders
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              _error ?? 'حدث خطأ غير متوقع',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _loadPhotos,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined,
                color: Colors.grey, size: 80),
            SizedBox(height: 16),
            Text(
              'لا توجد صور لعرضها حالياً',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 1.0, // Square items
      ),
      itemCount: _displayPhotos.length,
      itemBuilder: (context, index) {
        final photo = _displayPhotos[index];
        return GestureDetector(
          onTap: () => _navigateToImageViewer(index),
          child: Hero(
            tag: 'photo_${photo.photoUrl}_$index', // Unique tag
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: CachedNetworkImage(
                imageUrl: photo.thumbnailPhotoUrl.isNotEmpty
                    ? photo.thumbnailPhotoUrl
                    : photo.photoUrl, // Fallback to full photo if thumb is empty
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
