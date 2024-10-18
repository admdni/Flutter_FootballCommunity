import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'detail.dart';

void main() => runApp(FootballApp());

class FootballApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football Clubs',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, List<dynamic>> leagueClubs = {};
  List<String> leagues = [];
  String selectedLeague = 'All';
  bool isLoading = true;
  String errorMessage = '';
  TextEditingController searchController = TextEditingController();
  List<dynamic> popularClubs = [];

  final String apiKey = '';
  int currentPage = 1;
  bool hasMoreClubs = true;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    fetchClubs();
  }

  Future<void> _loadCachedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cached_clubs');
    if (cachedData != null) {
      Map<String, dynamic> data = json.decode(cachedData);
      setState(() {
        leagueClubs = Map<String, List<dynamic>>.from(data['leagueClubs']);
        leagues = ['All', ...leagueClubs.keys.toList()];
        popularClubs = data['popularClubs'];
        isLoading = false;
      });
    }
  }

  Future<void> _saveCachedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> data = {
      'leagueClubs': leagueClubs,
      'popularClubs': popularClubs,
    };
    prefs.setString('cached_clubs', json.encode(data));
  }

  Future<void> fetchClubs() async {
    if (!hasMoreClubs) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.football-data.org/v4/competitions?page=$currentPage'),
        headers: {'X-Auth-Token': apiKey},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final competitions = data['competitions'] as List;

        for (var competition in competitions) {
          final leagueResponse = await http.get(
            Uri.parse(
                'https://api.football-data.org/v4/competitions/${competition['code']}/teams'),
            headers: {'X-Auth-Token': apiKey},
          );
          if (leagueResponse.statusCode == 200) {
            final leagueData = json.decode(leagueResponse.body);
            leagueClubs[competition['name']] = leagueData['teams'];
          }
        }

        // Select popular clubs for the slider if it's the first page
        if (currentPage == 1) {
          popularClubs = leagueClubs.values.expand((i) => i).toList()
            ..sort((a, b) => (b['name'] ?? '').compareTo(a['name'] ?? ''));
          popularClubs = popularClubs.take(10).toList();
        }

        setState(() {
          leagues = ['All', ...leagueClubs.keys.toList()];
          isLoading = false;
          currentPage++;
          hasMoreClubs = competitions.isNotEmpty;
        });

        _saveCachedData();
      } else {
        throw Exception('Failed to load clubs');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  List<dynamic> getFilteredClubs() {
    if (selectedLeague == 'All') {
      return leagueClubs.values.expand((i) => i).toList();
    } else {
      return leagueClubs[selectedLeague] ?? [];
    }
  }

  Color getClubColor(String clubName) {
    return Colors.primaries[clubName.length % Colors.primaries.length];
  }

  void navigateToDetailPage(BuildContext context, Map<String, dynamic> club) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubDetailPage(
          club: club,
          team: {},
          player: {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredClubs = getFilteredClubs();

    return Scaffold(
      appBar: AppBar(
        title: Text('Football Clubs'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Slider
          if (popularClubs.isNotEmpty)
            CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 16 / 9,
                autoPlayCurve: Curves.fastOutSlowIn,
                enableInfiniteScroll: true,
                autoPlayAnimationDuration: Duration(milliseconds: 800),
                viewportFraction: 0.8,
              ),
              items: popularClubs.map((club) {
                return Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                      onTap: () => navigateToDetailPage(context, club),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          color: getClubColor(club['name'] ?? ''),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: club['crest'] ?? '',
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => Icon(
                                    Icons.sports_soccer,
                                    size: 50,
                                    color: Colors.white),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7)
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 10,
                              right: 10,
                              child: Text(
                                club['name'] ?? 'Unknown',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          SizedBox(height: 10),
          // League Chips
          Container(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: leagues.map((league) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(league),
                    selected: selectedLeague == league,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => selectedLeague = league);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          // Club List
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (!isLoading &&
                    scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                  fetchClubs();
                }
                return true;
              },
              child: ListView.builder(
                itemCount: filteredClubs.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == filteredClubs.length) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final club = filteredClubs[index];
                  final clubColor = getClubColor(club['name'] ?? '');
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: club['crest'] != null
                          ? CachedNetworkImage(
                              imageUrl: club['crest'],
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  CircleAvatar(
                                backgroundColor: clubColor,
                                child: Text(
                                  club['shortName']?[0] ??
                                      club['name']?[0] ??
                                      '?',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              width: 40,
                              height: 40,
                            )
                          : CircleAvatar(
                              backgroundColor: clubColor,
                              child: Text(
                                club['shortName']?[0] ??
                                    club['name']?[0] ??
                                    '?',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                      title: Text(club['name'] ?? 'Unknown Club'),
                      subtitle: Text(club['area']?['name'] ?? 'Unknown Area'),
                      onTap: () => navigateToDetailPage(context, club),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
