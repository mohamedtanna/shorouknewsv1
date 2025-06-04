import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/additional_models.dart'; // Contains ColumnModel
import '../../providers/news_provider.dart'; // For consistency, though columns might have their own provider
import '../../services/api_service.dart'; // To fetch column details
import '../../widgets/ad_banner.dart';
import '../../widgets/section_header.dart';
import '../../core/theme.dart';
import 'columns_module.dart'; // Assuming this module will fetch column details

class ColumnDetailScreen extends StatefulWidget {
  final String cdate;
  final String columnId;

  const ColumnDetailScreen({
    super.key,
    required this.cdate,
    required this.columnId,
  });

  @override
  State<ColumnDetailScreen> createState() => _ColumnDetailScreenState();
}

class _ColumnDetailScreenState extends State<ColumnDetailScreen> {
  // If you create a specific ColumnsProvider, use that instead of ApiService directly
  // For now, using ApiService as a placeholder for direct fetching.
  // final ColumnsModule _columnsModule = ColumnsModule(); // Use if ColumnsModule has getColumnDetails
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  ColumnModel? _columnDetail;
  List<ColumnModel> _relatedColumns = []; // Example for related content
  bool _isLoading = true;
  bool _isLoadingRelated = false;
  double _fontSize = 16.0;
  static const double _minFontSize = 12.0;
  static const double _maxFontSize = 24.0;

  @override
  void initState() {
    super.initState();
    _loadColumnDetail();
  }

  Future<void> _loadColumnDetail() async {
    setState(() => _isLoading = true);

    try {
      // Assuming ApiService has a method like getColumnDetail
      // If ColumnsModule handles this, call:
      // final columnDetail = await _columnsModule.getColumnDetails(widget.cdate, widget.columnId);
      final columnDetail =
          await _apiService.getColumnDetail(widget.cdate, widget.columnId);
      if (mounted) {
        setState(() {
          _columnDetail = columnDetail;
          _isLoading = false;
        });
        _loadRelatedColumns(columnDetail.columnistId, columnDetail.id);
        // Optionally, track column view here via a provider or service
        // context.read<AuthProvider>().trackColumnRead(widget.columnId);
            }
    } catch (e) {
      debugPrint('Error loading column detail: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في تحميل المقال')),
        );
      }
    }
  }

  Future<void> _loadRelatedColumns(
      String columnistId, String currentColumnId) async {
    if (columnistId.isEmpty) return;
    setState(() => _isLoadingRelated = true);
    try {
      // Fetch other columns by the same author or related by topic
      final columns = await _apiService.getColumns(
          columnistId: columnistId, pageSize: 5);
      if (mounted) {
        setState(() {
          _relatedColumns =
              columns.where((col) => col.id != currentColumnId).toList();
          _isLoadingRelated = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading related columns: $e');
      if (mounted) {
        setState(() => _isLoadingRelated = false);
      }
    }
  }

  void _shareColumn() {
    if (_columnDetail != null) {
      Share.share(
        '${_columnDetail!.title}\nبقلم: ${_columnDetail!.columnistArName}\n\n${_columnDetail!.summary}\n\n${_columnDetail!.canonicalUrl}',
        subject: _columnDetail!.title,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_columnDetail?.columnistArName ?? 'تفاصيل المقال'),
        actions: [
          if (_columnDetail != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareColumn,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _columnDetail == null
              ? const Center(
                  child: Text(
                    'لم يتم العثور على المقال',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadColumnDetail,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      const SliverToBoxAdapter(
                        child: AdBanner(
                            adUnit:
                                '/21765378867/ShorouknewsApp_LeaderBoard2'),
                      ),
                      SliverToBoxAdapter(
                        child: _buildBreadcrumb(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildAuthorHeader(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildColumnTitle(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildDates(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildReadingTools(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildColumnBody(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildShareSection(),
                      ),
                      if (_relatedColumns.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildRelatedColumns(),
                        ),
                      const SliverToBoxAdapter(
                        child: AdBanner(
                            adUnit: '/21765378867/ShorouknewsApp_Banner2'),
                      ),
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
          GestureDetector(
            onTap: () => context.go('/columns'),
            child: const Text(
              'رأي ومقالات',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const Text(' > ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              _columnDetail!.columnistArName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: CachedNetworkImageProvider(
                _columnDetail!.columnistPhotoUrl.isNotEmpty
                    ? _columnDetail!.columnistPhotoUrl
                    : 'https://via.placeholder.com/150'), // Fallback image
            onBackgroundImageError: (_, __) {}, // Handle error
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _columnDetail!.columnistArName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                // You can add author's title or short bio here if available
              ],
            ),
          ),
          IconButton(
              icon: const Icon(Icons.person_search),
              onPressed: () {
                context.go('/author/${_columnDetail!.columnistId}');
              })
        ],
      ),
    );
  }

  Widget _buildColumnTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Html(
        data: _columnDetail!.title,
        style: {
          "body": Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontSize: FontSize(22),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        },
      ),
    );
  }

  Widget _buildDates() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.calendar_today,
              color: AppTheme.tertiaryColor, size: 16),
          const SizedBox(width: 8),
          Text(
            _columnDetail!.creationDateFormattedDateTime.isNotEmpty
                ? _columnDetail!.creationDateFormattedDateTime
                : _columnDetail!.creationDateFormatted,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
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
            icon: const Icon(Icons.text_increase),
            onPressed: _increaseFontSize,
            tooltip: 'تكبير الخط',
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: _decreaseFontSize,
            tooltip: 'تصغير الخط',
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _shareColumn,
            icon: const Icon(Icons.share, size: 18),
            label: const Text('مشاركة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tertiaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Html(
        data: _columnDetail!.body,
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
            color: AppTheme.primaryColor,
            textDecoration: TextDecoration.underline,
          ),
          // Add more styles as needed for other HTML elements (h1, h2, img, etc.)
        },
        onLinkTap: (url, attributes, element) {
          // Handle link taps, e.g., open in browser
          // You might want to use url_launcher for this
          debugPrint('Link tapped: $url');
        },
      ),
    );
  }

  Widget _buildShareSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: ElevatedButton.icon(
        onPressed: _shareColumn,
        icon: const Icon(Icons.share),
        label: const Text('شارك المقال'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRelatedColumns() {
    if (_isLoadingRelated) {
      return const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()));
    }
    if (_relatedColumns.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SectionHeader(
            title: 'المزيد من مقالات الكاتب',
            icon: Icons.article_outlined,
            onMorePressed: () =>
                context.go('/columns?columnistId=${_columnDetail!.columnistId}'),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _relatedColumns.take(3).length, // Show up to 3 related
          itemBuilder: (context, index) {
            final column = _relatedColumns[index];
            // Using a simplified card for related columns
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                title: Text(
                  column.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  column.creationDateFormatted,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                onTap: () => context.go('/column/${column.cDate}/${column.id}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}