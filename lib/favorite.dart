import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'detail.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> favoriteTeams = [];
  List<Map<String, dynamic>> favoritePlayers = [];
  late TabController _tabController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      print('All keys in SharedPreferences: ${prefs.getKeys()}');

      List<String> favoriteTeamsJson =
          prefs.getStringList('favoriteTeams') ?? [];
      List<String> favoritePlayersJson =
          prefs.getStringList('favoritePlayers') ?? [];

      print('Favorite Teams JSON: $favoriteTeamsJson');
      print('Favorite Players JSON: $favoritePlayersJson');

      setState(() {
        favoriteTeams = favoriteTeamsJson
            .map((team) => Map<String, dynamic>.from(json.decode(team)))
            .toList();
        favoritePlayers = favoritePlayersJson
            .map((player) => Map<String, dynamic>.from(json.decode(player)))
            .toList();
        isLoading = false;
      });

      print('Loaded Favorite Teams: $favoriteTeams');
      print('Loaded Favorite Players: $favoritePlayers');
    } catch (e) {
      print('Error loading favorites: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _removeTeamFromFavorites(Map<String, dynamic> team) async {
    setState(() {
      favoriteTeams.removeWhere((t) => t['id'] == team['id']);
    });
    await _saveFavorites();
  }

  Future<void> _removePlayerFromFavorites(Map<String, dynamic> player) async {
    setState(() {
      favoritePlayers.removeWhere((p) => p['id'] == player['id']);
    });
    await _saveFavorites();
  }

  Future<void> _saveFavorites() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favoriteTeams',
          favoriteTeams.map((team) => json.encode(team)).toList());
      await prefs.setStringList('favoritePlayers',
          favoritePlayers.map((player) => json.encode(player)).toList());
      print('Favorites saved successfully');
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Teams'),
            Tab(text: 'Players'),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTeamsList(),
                _buildPlayersList(),
              ],
            ),
    );
  }

  Widget _buildTeamsList() {
    return favoriteTeams.isEmpty
        ? Center(child: Text('No favorite teams yet.'))
        : ListView.builder(
            itemCount: favoriteTeams.length,
            itemBuilder: (context, index) {
              final team = favoriteTeams[index];
              return Dismissible(
                key: Key(team['id'].toString()),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20.0),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _removeTeamFromFavorites(team);
                },
                child: ListTile(
                  leading: CachedNetworkImage(
                    imageUrl:
                        team['crestUrl'] ?? 'https://via.placeholder.com/50x50',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                    errorWidget: (context, url, error) =>
                        Icon(Icons.sports_soccer),
                  ),
                  title: Text(team['name'] ?? 'Unknown'),
                  subtitle: Text(team['area']['name'] ?? 'Unknown'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClubDetailPage(
                          club: team,
                          team: team,
                          player: {},
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
  }

  Widget _buildPlayersList() {
    return favoritePlayers.isEmpty
        ? Center(child: Text('No favorite players yet.'))
        : ListView.builder(
            itemCount: favoritePlayers.length,
            itemBuilder: (context, index) {
              final player = favoritePlayers[index];
              return Dismissible(
                key: Key(player['id'].toString()),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20.0),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _removePlayerFromFavorites(player);
                },
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(player['name'][0]),
                    backgroundColor: Colors.blue,
                  ),
                  title: Text(player['name'] ?? 'Unknown'),
                  subtitle: Text(player['position'] ?? 'Unknown'),
                  onTap: () {
                    // Navigate to player details page
                  },
                ),
              );
            },
          );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
