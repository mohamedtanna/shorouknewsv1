import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchTerm = query;
      // In a real app, you would trigger a search
      // based on the query and update a list of results.
      print('Searching for: $_searchTerm');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter search term',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _performSearch(_searchController.text);
                  },
                ),
              ),
              onSubmitted: _performSearch,
            ),
            SizedBox(height: 20),
            // This is where you would display search results.
            // For now, we'll just show the search term.
            _searchTerm.isNotEmpty
                ? Text('Displaying results for: $_searchTerm')
                : Container(),
            // Add a ListView or other widget here to display search results
            Expanded(
              child: Center(
                child: _searchTerm.isEmpty
                    ? Text('Start typing to search')
                    : Text('No results to display yet'), // Placeholder for results
              ),
            ),
          ],
        ),
      ),
    );
  }
}