import 'package:flutter/material.dart';

class SearchResultsScreen extends StatelessWidget {
  final String searchTerm;

  const SearchResultsScreen({Key? key, required this.searchTerm})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results for "$searchTerm"'),
      ),
      body: Center(
        child: Text('Displaying search results for: $searchTerm'),
      ),
    );
  }
}