import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football News',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: NewsScreen(),
    );
  }
}

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<dynamic> news = [];
  bool isLoading = false;
  String errorMessage = '';
  final String apiKey = '';
  int currentPage = 1;
  String searchQuery = 'football';
  String selectedCategory = '';
  TextEditingController searchController = TextEditingController();

  final List<String> categories = [
    'Premier League',
    'La Liga',
    'Champions League',
    'World Cup',
    'Transfer News'
  ];

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews({bool refresh = false}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
      if (refresh) {
        news.clear();
        currentPage = 1;
      }
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://newsapi.org/v2/everything?q=$searchQuery${selectedCategory.isNotEmpty ? "+$selectedCategory" : ""}&language=en&sortBy=publishedAt&apiKey=$apiKey&page=$currentPage'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          news.addAll(data['articles']);
          currentPage++;
        });
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onSearch() {
    setState(() {
      searchQuery = searchController.text;
      selectedCategory = '';
    });
    fetchNews(refresh: true);
  }

  void _onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
      searchController.clear();
      searchQuery = 'football';
    });
    fetchNews(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Football News',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.green,
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search news...',
                    hintStyle: TextStyle(color: Colors.white70),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search, color: Colors.white),
                      onPressed: _onSearch,
                    ),
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  onSubmitted: (_) => _onSearch(),
                ),
                SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          child: Text(category),
                          onPressed: () => _onCategorySelected(category),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: selectedCategory == category
                                ? Colors.green
                                : Colors.white,
                            backgroundColor: selectedCategory == category
                                ? Colors.white
                                : Colors.green[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: news.isEmpty
                ? Center(
                    child: isLoading
                        ? CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.green))
                        : Text(
                            errorMessage.isEmpty
                                ? 'No news found'
                                : errorMessage,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16),
                          ),
                  )
                : RefreshIndicator(
                    onRefresh: () => fetchNews(refresh: true),
                    color: Colors.green,
                    child: ListView.builder(
                      itemCount: news.length + 1,
                      itemBuilder: (context, index) {
                        if (index == news.length) {
                          return isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.green)))
                              : SizedBox.shrink();
                        }
                        return NewsItem(article: news[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class NewsItem extends StatelessWidget {
  final Map<String, dynamic> article;

  NewsItem({required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _launchURL(article['url']),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: article['urlToImage'] ?? '',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.green))),
                errorWidget: (context, url, error) =>
                    Icon(Icons.error, color: Colors.red),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article['title'] ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    article['description'] ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        article['source']['name'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatDate(article['publishedAt']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    final date = DateTime.parse(dateString);
    return DateFormat('MMM d, y').format(date);
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
