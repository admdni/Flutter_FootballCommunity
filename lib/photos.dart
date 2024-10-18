import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Photos',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: PhotosScreen(),
    );
  }
}

class PhotosScreen extends StatefulWidget {
  @override
  _PhotosScreenState createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  List<dynamic> photos = [];
  bool isLoading = true;
  String errorMessage = '';
  String currentCategory = 'plants';
  final String apiKey = ''; // Unsplash API anahtarınız

  @override
  void initState() {
    super.initState();
    fetchPhotos();
  }

  Future<void> fetchPhotos({String category = 'plants'}) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      currentCategory = category;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.unsplash.com/search/photos?query=$category&per_page=30&client_id=$apiKey'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          photos = data['results'];
        });
      } else {
        throw Exception('Failed to load photos');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore Football'),
      ),
      body: Column(
        children: [
          _buildCategoryButtons(),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(child: Text(errorMessage))
                    : GridView.builder(
                        padding: EdgeInsets.all(10),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3 / 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: photos.length,
                        itemBuilder: (ctx, i) => PhotoItem(photo: photos[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButtons() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: PLANT_CATEGORIES.length,
        itemBuilder: (context, index) {
          final category = PLANT_CATEGORIES[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              child: Text(
                category.toUpperCase(),
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    category == currentCategory ? Colors.green : Colors.grey,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => fetchPhotos(category: category),
            ),
          );
        },
      ),
    );
  }
}

class PhotoItem extends StatelessWidget {
  final Map<String, dynamic> photo;

  PhotoItem({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      margin: EdgeInsets.all(10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhotoDetailScreen(photo: photo),
            ),
          );
        },
        child: Column(
          children: <Widget>[
            Hero(
              tag: photo['id'],
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: CachedNetworkImage(
                  imageUrl: photo['urls']['small'],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                photo['description'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 14, // Metin boyutunu küçült
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis, // Metni kırpmak için
                maxLines: 2, // Maksimum 2 satır göster
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoDetailScreen extends StatelessWidget {
  final Map<String, dynamic> photo;

  PhotoDetailScreen({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: Hero(
            tag: photo['id'],
            child: CachedNetworkImage(
              imageUrl: photo['urls']['regular'],
              fit: BoxFit.contain,
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }
}

const List<String> PLANT_CATEGORIES = [
  'soccer',
  'football',
  'striker',
  'goalkeeper',
  'defender',
  'midfielder',
  'forward',
  'coach',
  'referee',
  'penalty',
  'offside',
  'tackle',
  'dribble',
  'goal',
  'assist',
  'corner',
  'freekick',
  'header',
  'pitch',
  'stadium',
  'league',
  'tournament',
  'championship',
  'worldcup',
  'transfer',
  'tactics',
  'formation',
  'cleats',
  'jersey',
  'captain'
];
