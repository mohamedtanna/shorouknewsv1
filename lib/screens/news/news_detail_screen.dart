import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../models/news_model.dart';
import '../../services/api_service.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/section_header.dart';
import '../../widgets/news_card.dart';
import '../../core/theme.dart';

class NewsDetailScreen extends StatefulWidget {
  final String cdate;
  final String newsId;

  const NewsDetailScreen({
    super.key,
    required this.cdate,
    required this.newsId,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  
  NewsArticle? _newsDetail;
  List<NewsArticle> _relatedNews = [];
  bool _isLoading = true;
  bool _isLoadingRelated = false;
  double _fontSize = 16.0;
  static const double _minFontSize = 12.0;
  static const double _maxFontSize = 24.0;

  @override
  void initState() {
    super.initState();
    _loadNewsDetail();
  }

  Future<void> _loadNewsDetail() async {
    setState(() => _isLoading = true);
    
    try {
      final newsDetail = await _apiService.getNewsDetail(widget.cdate, widget.newsId);
      if (newsDetail != null) {
        setState(() => _newsDetail = newsDetail);
        _loadRelatedNews();
      }
    } catch (e) {
      debugPrint('Error loading news detail: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في تحميل الخبر')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRelatedNews() async {
    if (_newsDetail == null) return;
    
    setState(() => _isLoadingRelated = true);
    
    try {
      final relatedNews = await _apiService.getNews(
        sectionId: _newsDetail!.sectionId,
        pageSize: 6,
      );
      setState(() {
        _relatedNews = relatedNews.where((news) => news.id != _newsDetail!.id).toList();
      });
    } catch (e) {
      debugPrint('Error loading related news: $e');
    } finally {
      setState(() => _isLoadingRelated = false);
    }
  }

  void _shareNews() {
    if (_newsDetail != null) {
      Share.share(
        '${_newsDetail!.title}\n\n${_newsDetail!.summary}\n\n${_newsDetail!.canonicalUrl}',
        subject: _newsDetail!.title,
      );
    }
  }

  void _increaseFontSize() {
    if (_fontSize < _maxFontSize) {
      setState(() => _fontSize += 1);
    }
  }

  void _decreaseFontSize() {
    if (_fontSize > _minFontSize) {
      setState(() => _fontSize -= 1);
    }
  }

  void _showPhotoGallery(int initialIndex) {
    if (_newsDetail?.relatedPhotos.isEmpty ?? true) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoGalleryScreen(
          photos: _newsDetail!.relatedPhotos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الخبر'),
        actions: [
          if (_newsDetail != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareNews,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _newsDetail == null
              ? const Center(
                  child: Text(
                    'لم يتم العثور على الخبر',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNewsDetail,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Ad Banner
                      const SliverToBoxAdapter(
                        child: AdBanner(adUnit: '/21765378867/ShorouknewsApp_LeaderBoard2'),
                      ),
                      
                      // Breadcrumb
                      SliverToBoxAdapter(
                        child: _buildBreadcrumb(),
                      ),
                      
                      // Main Image and Title
                      SliverToBoxAdapter(
                        child: _buildMainContent(),
                      ),
                      
                      // Editor and Source
                      if (_newsDetail!.editorAndSource.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildEditorSource(),
                        ),
                      
                      // Dates
                      SliverToBoxAdapter(
                        child: _buildDates(),
                      ),
                      
                      // Reading Tools
                      SliverToBoxAdapter(
                        child: _buildReadingTools(),
                      ),
                      
                      // News Body
                      SliverToBoxAdapter(
                        child: _buildNewsBody(),
                      ),
                      
                      // Share Button
                      SliverToBoxAdapter(
                        child: _buildShareSection(),
                      ),
                      
                      // Related Photos
                      if (_newsDetail!.relatedPhotos.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildRelatedPhotos(),
                        ),
                      
                      // Related News
                      if (_relatedNews.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildRelatedNews(),
                        ),
                      
                      // Ad Banner
                      const SliverToBoxAdapter(
                        child: AdBanner(adUnit: '/21765378867/ShorouknewsApp_Banner2'),
                      ),
                      
                      // More News Section
                      SliverToBoxAdapter(
                        child: _buildMoreNewsSection(),
                      ),
                      
                      // Bottom spacing
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 20),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
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
          if (_newsDetail!.sectionArName.isNotEmpty) ...[
            GestureDetector(
              onTap: () => context.go('/news?sectionId=${_newsDetail!.sectionId}&sectionName=${_newsDetail!.sectionArName}'),
              child: Text(
                _newsDetail!.sectionArName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: _newsDetail!.photoUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Html(
              data: _newsDetail!.title,
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(20),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorSource() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.tertiaryColor,
      child: Text(
        _newsDetail!.editorAndSource,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDates() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text(
                'نشر في: ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                _newsDetail!.publishDateFormatted,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text(
                'آخر تحديث: ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                _newsDetail!.lastModificationDateFormatted,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadingTools() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Font size controls
          Row(
            children: [
              IconButton(
                onPressed: _increaseFontSize,
                icon: const Text('+ع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: _decreaseFontSize,
                icon: const Text('-ع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Share button
          ElevatedButton.icon(
            onPressed: _shareNews,
            icon: const Icon(Icons.share, color: AppTheme.tertiaryColor),
            label: const Text(
              'مشاركة',
              style: TextStyle(color: AppTheme.tertiaryColor),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppTheme.tertiaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsBody() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Html(
        data: _newsDetail!.body,
        style: {
          "body": Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontSize: FontSize(_fontSize),
            lineHeight: const LineHeight(1.6),
          ),
          "p": Style(
            fontSize: FontSize(_fontSize),
            lineHeight: const LineHeight(1.6),
            margin: Margins.only(bottom: 16),
          ),
          "a": Style(
            color: AppTheme.primaryColor,
            textDecoration: TextDecoration.underline,
          ),
        ),
        onLinkTap: (url, attributes, element) {
          // Handle link taps
          debugPrint('Link tapped: $url');
        },
      ),
    );
  }

  Widget _buildShareSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: ElevatedButton.icon(
        onPressed: _shareNews,
        icon: const Icon(Icons.share, color: AppTheme.tertiaryColor),
        label: const Text(
          'مشاركة',
          style: TextStyle(color: AppTheme.tertiaryColor),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppTheme.tertiaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildRelatedPhotos() {
    return Column(
      children: [
        SectionHeader(
          title: 'صور متعلقة',
          icon: Icons.photo_library,
          onMorePressed: () => _showPhotoGallery(0),
          moreText: 'المعرض',
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _newsDetail!.relatedPhotos.length,
            itemBuilder: (context, index) {
              final photo = _newsDetail!.relatedPhotos[index];
              return GestureDetector(
                onTap: () => _showPhotoGallery(index),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(left: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: photo.thumbnailPhotoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedNews() {
    return Column(
      children: [
        SectionHeader(
          title: 'أخبار متعلقة',
          icon: Icons.article,
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _newsDetail!.relatedNews.length,
          itemBuilder: (context, index) {
            final relatedNews = _newsDetail!.relatedNews[index];
            return GestureDetector(
              onTap: () => context.go('/news/${relatedNews.cDate}/${relatedNews.id}'),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: relatedNews.thumbnailPhotoUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Text(
                        relatedNews.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMoreNewsSection() {
    if (_relatedNews.isEmpty) return const SizedBox.shrink();
    
    return Column(
      children: [
        SectionHeader(
          title: 'المزيد من الأخبار',
          icon: Icons.article,
          onMorePressed: () => context.go('/news?sectionId=${_newsDetail!.sectionId}&sectionName=${_newsDetail!.sectionArName}'),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _relatedNews.length.clamp(0, 4),
          itemBuilder: (context, index) {
            final news = _relatedNews[index];
            return NewsCard(
              article: news,
              isHorizontal: true,
              onTap: () => context.go('/news/${news.cDate}/${news.id}'),
            );
          },
        ),
      ],
    );
  }
}

// Photo Gallery Screen
class PhotoGalleryScreen extends StatelessWidget {
  final List<RelatedPhoto> photos;
  final int initialIndex;

  const PhotoGalleryScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${initialIndex + 1} من ${photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(photos[index].photoUrl),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2.0,
            heroAttributes: PhotoViewHeroAttributes(tag: 'photo_$index'),
          );
        },
        itemCount: photos.length,
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        pageController: PageController(initialPage: initialIndex),
        onPageChanged: (index) {
          // Update app bar title if needed
        },
      ),
    );
  }
}