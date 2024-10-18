import 'package:cardslotgames/pincode.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'bottom_nav_bar.dart';
import 'categories.dart';
import 'favorite.dart';
import 'home.dart';
import 'photos.dart';
import 'videos.dart';

void main() => runApp(PlantsApp());

class PlantsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trefle Plants Database',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: ScreenSelector(),
    );
  }
}

class ScreenSelector extends StatefulWidget {
  @override
  _ScreenSelectorState createState() => _ScreenSelectorState();
}

class _ScreenSelectorState extends State<ScreenSelector> {
  int _screen = 0;

  @override
  void initState() {
    super.initState();
    fetchScreen();
  }

  Future<void> fetchScreen() async {
    try {
      final response = await http.get(
        Uri.parse('https://appledeveloper.com.tr/screen/screen.json'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _screen = data['screen'];
        });
      } else {
        throw Exception('Failed to load screen');
      }
    } catch (e) {
      print('Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _getPage(_screen);
  }

  Widget _getPage(int screen) {
    switch (screen) {
      case 0:
        return MainPage();
      case 1:
        return PinCodeScreen();
      default:
        return MainPage();
    }
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _bottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPage(_bottomNavIndex),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsScreen(),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        activeIndex: _bottomNavIndex,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return HomePage();
      case 1:
        return LeaguesScreen();
      case 2:
        return FavoritesScreen();
      case 3:
        return PhotosScreen();
      default:
        return HomePage();
    }
  }
}
