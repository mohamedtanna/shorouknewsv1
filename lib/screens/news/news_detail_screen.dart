import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_iframe/flutter_html_iframe.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart'; // For loading effects
import 'package:url_launcher/url_launcher.dart'; // For opening external links

// Models
import 'package:shorouk_news/models/new_model.dart';

// Services
import '../../services/api_service.dart';
// import '../../providers/auth_provider.dart'; // If you want to track news views

// Widgets
// import '../../widgets/ad_banner.dart';
import '../../widgets/section_header.dart'; // Corrected import path
import '../../widgets/news_card.dart'; // For related news

// Core
import '../../core/theme.dart';

// Note: The PhotoGalleryScreen is imported via app_router.dart when navigating.
// We don't need a direct import here if using GoRouter for navigation to it.

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
  List<NewsArticle> _moreNewsFromSection = []; // For "More News" section
  bool _isLoading = true;
  String? _loadingError; // To store error messages
  // bool _isLoadingRelated = false; // This was unused, removed. Related news are part of _newsDetail or fetched in _loadMoreNewsFromSection
  bool _isLoadingMoreNews = false; // For "More News from Section"

  double _fontSize = 16.0; // Default font size for article body
  static const double _minFontSize = 12.0;
  static const double _maxFontSize = 24.0;

  @override
  void initState() {
    super.initState();
    _loadNewsDetail();
  }

  Future<void> _loadNewsDetail({bool refresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadingError = null;
      if (refresh) {
        _newsDetail = null; // Clear existing detail on refresh
        _moreNewsFromSection.clear();
      }
    });

    try {
      final newsDetail =
          await _apiService.getNewsDetail(widget.cdate, widget.newsId);
      if (mounted) {
        setState(() {
          _newsDetail = newsDetail;
        });
        _loadMoreNewsFromSection(newsDetail.sectionId, newsDetail.id);
        // Example: Track news view using AuthProvider
        // try {
        //   context.read<AuthProvider>().trackNewsRead(widget.newsId);
        // } catch (e) {
        //   debugPrint("Error tracking news read: $e");
        // }
      }
    } catch (e) {
      debugPrint('Error loading news detail: $e');
      if (mounted) {
        setState(() {
          _loadingError = 'خطأ في تحميل الخبر. يرجى المحاولة مرة أخرى.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Loads more news from the same section, excluding the current article.
  Future<void> _loadMoreNewsFromSection(
      String sectionId, String currentNewsId) async {
    if (sectionId.isEmpty || !mounted) return;

    if (mounted) setState(() => _isLoadingMoreNews = true);
    try {
      final newsList = await _apiService.getNews(
        sectionId: sectionId,
        pageSize: 4, // Fetch a few articles for "More News"
      );
      if (mounted) {
        setState(() {
          _moreNewsFromSection =
              newsList.where((news) => news.id != currentNewsId).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading more news from section: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMoreNews = false);
      }
    }
  }

  void _shareNews() {
    if (_newsDetail != null) {
      String shareText = '${_newsDetail!.title}\n\n';
      if (_newsDetail!.summary.isNotEmpty) {
        shareText += '${_newsDetail!.summary}\n\n';
      }
      shareText += _newsDetail!.canonicalUrl; // Link to the web version

      Share.share(
        shareText,
        subject: _newsDetail!.title,
      );
    }
  }

  void _increaseFontSize() {
    if (_fontSize < _maxFontSize) {
      if (mounted) setState(() => _fontSize += 1);
    }
  }

  void _decreaseFontSize() {
    if (_fontSize > _minFontSize) {
      if (mounted) setState(() => _fontSize -= 1);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Navigates to the photo gallery screen.
  void _showPhotoGallery(int initialIndex) {
    if (_newsDetail?.relatedPhotos.isEmpty ?? true) return;

    context.goNamed(
      'image-viewer',
      extra: {
        'photos': _newsDetail!.relatedPhotos,
        'initialIndex': initialIndex,
        'galleryTitle': 'صور متعلقة بالخبر: ${_newsDetail!.title}',
      },
    );
  }

  Future<void> _handleLinkTap(String? url) async {
    if (url != null) {
      final Uri? uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر فتح الرابط: $url')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_newsDetail?.sectionArName ?? 'تفاصيل الخبر'),
        actions: [
          if (_newsDetail != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'مشاركة الخبر',
              onPressed: _shareNews,
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingShimmer()
          : _loadingError != null
              ? _buildErrorState(_loadingError!)
              : _newsDetail == null
                  ? _buildErrorState('لم يتم العثور على الخبر.')
                  : RefreshIndicator(
                      onRefresh: () => _loadNewsDetail(refresh: true),
                      color: AppTheme.primaryColor,
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          // const SliverToBoxAdapter(
                          //   child: AdBanner(
                          //       adUnit:
                          //           '/21765378867/ShorouknewsApp_LeaderBoard2'),
                          // ),
                          SliverToBoxAdapter(child: _buildBreadcrumb()),
                          SliverToBoxAdapter(child: _buildMainContent()),
                          if (_newsDetail!.editorAndSource.isNotEmpty)
                            SliverToBoxAdapter(child: _buildEditorSource()),
                          SliverToBoxAdapter(child: _buildDates()),
                          SliverToBoxAdapter(child: _buildReadingTools()),
                          SliverToBoxAdapter(child: _buildNewsBody()),
                          SliverToBoxAdapter(child: _buildShareSection()),
                          if (_newsDetail!.relatedPhotos.isNotEmpty)
                            SliverToBoxAdapter(child: _buildRelatedPhotos()),
                          if (_newsDetail!.relatedNews.isNotEmpty)
                            SliverToBoxAdapter(
                                child: _buildCuratedRelatedNews()),
                          // const SliverToBoxAdapter(
                          //   child: AdBanner(
                          //       adUnit: '/21765378867/ShorouknewsApp_Banner2'),
                          // ),
                          if (_moreNewsFromSection.isNotEmpty ||
                              _isLoadingMoreNews)
                            SliverToBoxAdapter(
                                child: _buildMoreNewsFromSectionWidget()),
                          const SliverToBoxAdapter(child: SizedBox(height: 20)),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: double.infinity,
                  height: 200.0,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12))),
              const SizedBox(height: 16.0),
              Container(
                  width: double.infinity,
                  height: 24.0,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8.0),
              Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 20.0,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 16.0),
              Container(
                  width: double.infinity,
                  height: 100.0,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 16.0),
              Container(
                  width: double.infinity,
                  height: 100.0,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red[600], size: 70),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.black87),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: () => _loadNewsDetail(refresh: true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    if (_newsDetail == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        border: const Border(
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
                  fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
          ),
          const Text(' > ', style: TextStyle(fontWeight: FontWeight.bold)),
          // Corrected: Conditionally add GestureDetector only if sectionArName is not empty
          if (_newsDetail!.sectionArName.isNotEmpty)
            Expanded(
              child: GestureDetector(
                onTap: () => context.go(
                    '/news?sectionId=${_newsDetail!.sectionId}&sectionName=${Uri.encodeComponent(_newsDetail!.sectionArName)}'),
                child: Text(
                  _newsDetail!.sectionArName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          else
            const Expanded(
                // Ensure Row children are properly expanded or sized
                child: Text('خبر',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_newsDetail == null) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.all(0),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Stack(
        children: [
          if (_newsDetail!.photoUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: _newsDetail!.photoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image_outlined,
                      color: Colors.grey, size: 50),
                ),
              ),
            )
          else
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported_outlined,
                    color: Colors.grey, size: 50),
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(
                        (255 * 0.1).round()), // Corrected withOpacity
                    Colors.black.withAlpha(
                        (255 * 0.75).round()), // Corrected withOpacity
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
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
                    textShadow: [
                      const Shadow(
                          blurRadius: 2.0,
                          color: Colors.black54,
                          offset: Offset(1, 1))
                    ]),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorSource() {
    if (_newsDetail == null || _newsDetail!.editorAndSource.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.tertiaryColor
          .withAlpha((255 * 0.15).round()), // Corrected withOpacity
      width: double.infinity,
      child: Text(
        _newsDetail!.editorAndSource,
        style: const TextStyle(
          // Corrected: Color does not have shade900. Using primary for contrast or a darker tertiary.
          color: AppTheme
              .primaryColor, // Or: Color.fromRGBO((AppTheme.tertiaryColor.red * 0.6).round(), (AppTheme.tertiaryColor.green * 0.6).round(), (AppTheme.tertiaryColor.blue * 0.6).round(),1,),
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDates() {
    if (_newsDetail == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor
          .withAlpha((255 * 0.05).round()), // Corrected withOpacity
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: AppTheme.primaryColor, size: 16),
              const SizedBox(width: 8),
              const Text(
                'نشر في: ',
                style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              Text(
                '${_newsDetail!.publishDateFormatted} - ${_newsDetail!.publishTimeFormatted}',
                style: TextStyle(color: Colors.grey[800], fontSize: 13),
              ),
            ],
          ),
          if (_newsDetail!.lastModificationDateFormatted.isNotEmpty &&
              _newsDetail!.lastModificationDateFormatted !=
                  _newsDetail!.publishDateFormatted) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_outlined,
                    color: AppTheme.primaryColor, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'آخر تحديث: ',
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                Text(
                  _newsDetail!.lastModificationDateFormatted,
                  style: TextStyle(color: Colors.grey[800], fontSize: 13),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildReadingTools() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Text('حجم الخط:', style: TextStyle(fontSize: 14)),
          IconButton(
            icon: const Icon(Icons.text_increase_outlined),
            onPressed: _increaseFontSize,
            tooltip: 'تكبير الخط',
            color: AppTheme.primaryColor,
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease_outlined),
            onPressed: _decreaseFontSize,
            tooltip: 'تصغير الخط',
            color: AppTheme.primaryColor,
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _shareNews,
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('مشاركة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tertiaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsBody() {
    if (_newsDetail == null) return const SizedBox.shrink();
    final String unescapedBody = HtmlUnescape().convert(_newsDetail!.body);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Html(
        data: unescapedBody,
        style: {
          "body": Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontSize: FontSize(_fontSize),
            lineHeight: const LineHeight(1.7),
            textAlign: TextAlign.justify,
          ),
          "p": Style(
            fontSize: FontSize(_fontSize),
            lineHeight: const LineHeight(1.7),
            margin: Margins.only(bottom: 16),
          ),
          "a": Style(
            color: AppTheme.tertiaryColor,
            textDecoration: TextDecoration.underline,
          ),
          "img": Style(
            width: Width(MediaQuery.of(context).size.width - 32),
            padding: HtmlPaddings.symmetric(vertical: 8),
          ),
        },
        onLinkTap: (url, attributes, element) => _handleLinkTap(url),
        extensions: const [IframeHtmlExtension()],
      ),
    );
  }

  Widget _buildShareSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      alignment: Alignment.center,
      child: ElevatedButton.icon(
        onPressed: _shareNews,
        icon: const Icon(Icons.share_rounded),
        label: const Text('شارك هذا الخبر'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRelatedPhotos() {
    if (_newsDetail == null || _newsDetail!.relatedPhotos.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        SectionHeader(
          // Corrected: Assuming SectionHeader is a widget class
          title: 'صور متعلقة بالخبر',
          icon: Icons.photo_library_outlined,
          onMorePressed: () => _showPhotoGallery(0),
          moreText: 'عرض كل الصور',
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: _newsDetail!.relatedPhotos.length,
            itemBuilder: (context, index) {
              final photo = _newsDetail!.relatedPhotos[index];
              return GestureDetector(
                onTap: () => _showPhotoGallery(index),
                child: Hero(
                  tag: 'photo_${photo.photoUrl}_$index',
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: photo.thumbnailPhotoUrl.isNotEmpty
                                ? photo.thumbnailPhotoUrl
                                : photo.photoUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(color: Colors.white)),
                            errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image_outlined,
                                    color: Colors.grey)),
                          ),
                          if (photo.photoCaption.isNotEmpty)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                color: Colors.black.withAlpha((255 * 0.6)
                                    .round()), // Corrected withOpacity
                                child: Text(
                                  photo.photoCaption,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCuratedRelatedNews() {
    if (_newsDetail == null || _newsDetail!.relatedNews.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        const SectionHeader(
          // Corrected: Assuming SectionHeader is a widget class
          title: 'أخبار ذات صلة',
          icon: Icons.article_outlined,
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _newsDetail!.relatedNews.length.clamp(0, 4),
          itemBuilder: (context, index) {
            final relatedNewsItem = _newsDetail!.relatedNews[index];
            final tempArticle = NewsArticle(
                id: relatedNewsItem.id,
                cDate: relatedNewsItem.cDate,
                title: relatedNewsItem.title,
                summary: '',
                body: '',
                photoUrl: relatedNewsItem.thumbnailPhotoUrl,
                thumbnailPhotoUrl: relatedNewsItem.thumbnailPhotoUrl,
                sectionId: _newsDetail!.sectionId,
                sectionArName: '',
                publishDate: '',
                publishDateFormatted: '',
                publishTimeFormatted: '',
                lastModificationDate: '',
                lastModificationDateFormatted: '',
                editorAndSource: '',
                canonicalUrl:
                    '/news/${relatedNewsItem.cDate}/${relatedNewsItem.id}',
                relatedPhotos: [],
                relatedNews: []);
            return NewsCard(
              article: tempArticle,
              onTap: () => context
                  .go('/news/${relatedNewsItem.cDate}/${relatedNewsItem.id}'),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMoreNewsFromSectionWidget() {
    if (_isLoadingMoreNews && _moreNewsFromSection.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
              height: 24,
              width: 150,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(4))),
        ),
      );
    }
    if (_moreNewsFromSection.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SectionHeader(
          // Corrected: Assuming SectionHeader is a widget class
          title: 'المزيد من قسم "${_newsDetail?.sectionArName ?? ''}"',
          icon: Icons.library_books_outlined,
          onMorePressed: () => context.go(
              '/news?sectionId=${_newsDetail!.sectionId}&sectionName=${Uri.encodeComponent(_newsDetail!.sectionArName)}'),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _moreNewsFromSection.length,
          itemBuilder: (context, index) {
            final news = _moreNewsFromSection[index];
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
