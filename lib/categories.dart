import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football Leagues',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.blue,
        ),
      ),
      home: LeaguesScreen(),
    );
  }
}

class LeaguesScreen extends StatefulWidget {
  @override
  _LeaguesScreenState createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  List<dynamic> leagues = [];
  List<dynamic> filteredLeagues = [];
  bool isLoading = true;
  String errorMessage = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchLeagues();
  }

  Future<void> fetchLeagues({bool refresh = false}) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'leagues';
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null && !refresh) {
        final data = json.decode(cachedData);
        processLeaguesData(data);
      } else {
        final response = await http.get(
          Uri.parse(
              'https://www.thesportsdb.com/api/v1/json/3/all_leagues.php'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          processLeaguesData(data);

          prefs.setString(cacheKey, response.body);
          prefs.setString(
              '${cacheKey}_timestamp', DateTime.now().toIso8601String());
        } else {
          throw Exception('Failed to load leagues: ${response.statusCode}');
        }
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

  void processLeaguesData(Map<String, dynamic> data) {
    setState(() {
      leagues = data['leagues']
          .where((league) => league['strSport'] == 'Soccer')
          .toList();
      filteredLeagues = List.from(leagues);
    });
  }

  void filterLeagues(String query) {
    setState(() {
      filteredLeagues = leagues
          .where((league) =>
              league['strLeague'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Football Leagues',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Leagues',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: filterLeagues,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => fetchLeagues(refresh: true),
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Text(errorMessage,
                              style: TextStyle(color: Colors.red)))
                      : GridView.builder(
                          padding: EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredLeagues.length,
                          itemBuilder: (ctx, i) =>
                              LeagueItem(league: filteredLeagues[i]),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class LeagueItem extends StatelessWidget {
  final Map<String, dynamic> league;

  LeagueItem({required this.league});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamsScreen(
                  leagueId: league['idLeague'],
                  leagueName: league['strLeague']),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[50]!, Colors.blue[100]!],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Center(
                  child: league['strBadge'] != null
                      ? CachedNetworkImage(
                          imageUrl: league['strBadge'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.sports_soccer, size: 80),
                        )
                      : Icon(Icons.sports_soccer, size: 80, color: Colors.blue),
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  league['strLeague'] ?? 'Unknown',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              SizedBox(height: 5),
              Text(
                league['strCountry'] ?? 'Unknown',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeamsScreen extends StatefulWidget {
  final String leagueId;
  final String leagueName;

  TeamsScreen({required this.leagueId, required this.leagueName});

  @override
  _TeamsScreenState createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  List<dynamic> teams = [];
  List<dynamic> filteredTeams = [];
  bool isLoading = true;
  String errorMessage = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTeams();
  }

  Future<void> fetchTeams() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'teams_${widget.leagueId}';
      final cachedData = prefs.getString(cacheKey);
      final cacheTimestamp = prefs.getString('${cacheKey}_timestamp');

      if (cachedData != null && cacheTimestamp != null) {
        final cacheDateTime = DateTime.parse(cacheTimestamp);
        if (DateTime.now().difference(cacheDateTime).inHours < 24) {
          final data = json.decode(cachedData);
          setState(() {
            teams = data['teams'];
            filteredTeams = teams;
          });
          return;
        }
      }

      final response = await http.get(
        Uri.parse(
            'https://www.thesportsdb.com/api/v1/json/3/search_all_teams.php?l=${Uri.encodeComponent(widget.leagueName)}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['teams'] != null) {
          setState(() {
            teams = data['teams'];
            filteredTeams = teams;
          });
          prefs.setString(cacheKey, json.encode(data));
          prefs.setString(
              '${cacheKey}_timestamp', DateTime.now().toIso8601String());
        } else {
          throw Exception('No teams found for this league');
        }
      } else {
        throw Exception('Failed to load teams: ${response.statusCode}');
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

  void filterTeams(String query) {
    setState(() {
      filteredTeams = teams
          .where((team) =>
              team['strTeam'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teams in ${widget.leagueName}',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Teams',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: filterTeams,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchTeams,
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Text(errorMessage,
                              style:
                                  TextStyle(color: Colors.red, fontSize: 16)))
                      : filteredTeams.isEmpty
                          ? Center(
                              child: Text("No teams found for this league.",
                                  style: TextStyle(fontSize: 18)))
                          : GridView.builder(
                              padding: EdgeInsets.all(16),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: filteredTeams.length,
                              itemBuilder: (ctx, i) =>
                                  TeamItem(team: filteredTeams[i]),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class TeamItem extends StatelessWidget {
  final Map<String, dynamic> team;

  TeamItem({required this.team});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClubDetailPage(team: team),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[50]!, Colors.blue[100]!],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Center(
                  child: team['strTeamBadge'] != null
                      ? CachedNetworkImage(
                          imageUrl: team['strTeamBadge'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.sports_soccer, size: 80),
                        )
                      : Icon(Icons.sports_soccer, size: 80, color: Colors.blue),
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  team['strTeam'] ?? 'Unknown',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              SizedBox(height: 5),
              Text(
                team['strCountry'] ?? 'Unknown',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClubDetailPage extends StatelessWidget {
  final Map<String, dynamic> team;

  ClubDetailPage({required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(team['strTeam'] ?? 'Unknown',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[200],
              child: team['strTeamBanner'] != null
                  ? CachedNetworkImage(
                      imageUrl: team['strTeamBanner'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.sports_soccer, size: 100),
                    )
                  : Icon(Icons.sports_soccer, size: 100),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    team['strTeam'] ?? 'Unknown',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  _buildInfoRow('Country', team['strCountry'] ?? 'Unknown'),
                  _buildInfoRow('Founded',
                      team['intFormedYear']?.toString() ?? 'Unknown'),
                  _buildInfoRow('Stadium', team['strStadium'] ?? 'Unknown'),
                  _buildInfoRow('League', team['strLeague'] ?? 'Unknown'),
                  SizedBox(height: 20),
                  Text(
                    'Description',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(team['strDescriptionEN'] ?? 'No description available.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
