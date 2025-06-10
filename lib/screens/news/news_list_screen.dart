import 'package:flutter/material.dart';

class NewsListScreen extends StatefulWidget {
  final String section;

  const NewsListScreen({super.key, required this.section});

  @override
  _NewsListScreenState createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  List<NewModel> newsList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    // Replace with your actual data fetching logic (e.g., from an API)
    // For now, using dummy data
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    setState(() {
      newsList = List.generate(
        10,
        (index) => NewModel(
          id: index.toString(),
          title: 'News Article Title ${index + 1}',
          imageUrl: 'https://via.placeholder.com/150',
          summary: 'This is a summary of the news article ${index + 1}.',
          publishDate: DateTime.now().subtract(Duration(hours: index)),
          section: widget.section,
        ),
      );
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.section} News'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final newsItem = newsList[index];
                return NewsCard(
                  news: newsItem,
                  onTap: () {
                    // Navigate to news detail screen
                    // Navigator.pushNamed(context, '/newsDetail', arguments: newsItem.id);
                  },
                );
              },
            ),
    );
  }
}

// Dummy NewModel class for demonstration
class NewModel {
  final String id;
  final String title;
  final String imageUrl;
  final String summary;
  final DateTime publishDate;
  final String section;

  NewModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.summary,
    required this.publishDate,
    required this.section,
  });
}

// Dummy NewsCard widget for demonstration
class NewsCard extends StatelessWidget {
  final NewModel news;
  final VoidCallback? onTap;

  const NewsCard({super.key, required this.news, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                news.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      news.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Published: ${news.publishDate.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
