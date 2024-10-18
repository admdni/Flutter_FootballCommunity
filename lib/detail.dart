import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ClubDetailPage extends StatefulWidget {
  final Map<String, dynamic> club;
  final Map<String, dynamic> team;

  ClubDetailPage(
      {required this.club,
      required this.team,
      required Map<String, dynamic> player});

  @override
  _ClubDetailPageState createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage>
    with SingleTickerProviderStateMixin {
  bool isFavorite = false;
  List<String> favoritePlayersIds = [];
  late Color primaryColor;
  late Color secondaryColor;
  late TabController _tabController;
  final List<String> _tabs = ['Overview', 'Squad', 'Matches', 'Statistics'];

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    _setClubColors();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setClubColors() {
    try {
      final colors = widget.club['clubColors']?.split('/') ?? [];
      if (colors.isNotEmpty) {
        primaryColor = _parseColor(colors[0].trim());
        secondaryColor = colors.length > 1
            ? _parseColor(colors[1].trim())
            : primaryColor.withOpacity(0.7);
      } else {
        // Varsayılan renkler
        primaryColor = Colors.blue;
        secondaryColor = Colors.blueAccent;
      }
    } catch (e) {
      print('Error setting club colors: $e');
      // Hata durumunda varsayılan renkler
      primaryColor = Colors.blue;
      secondaryColor = Colors.blueAccent;
    }
  }

  Color _parseColor(String colorName) {
    // Renk isimlerini hexadecimal kodlara dönüştürme
    final colorMap = {
      'red': 0xFFFF0000,
      'blue': 0xFF0000FF,
      'green': 0xFF00FF00,
      'yellow': 0xFFFFFF00,
      'purple': 0xFF800080,
      'orange': 0xFFFFA500,
      'black': 0xFF000000,
      'white': 0xFFFFFFFF,
      'gray': 0xFF808080,
      'maroon': 0xFF800000,
      'navy': 0xFF000080,
    };

    final lowerCaseColorName = colorName.toLowerCase();
    if (colorMap.containsKey(lowerCaseColorName)) {
      return Color(colorMap[lowerCaseColorName]!);
    }

    // Eğer renk ismi bulunamazsa, hexadecimal kod olarak parse etmeyi dene
    try {
      return Color(
          int.parse(colorName.replaceAll('#', ''), radix: 16) + 0xFF000000);
    } catch (e) {
      print('Could not parse color: $colorName');
      return Colors.blue; // Varsayılan renk
    }
  }

  _loadFavoriteStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isFavorite = prefs.getBool('club_${widget.club['id']}') ?? false;
      favoritePlayersIds = prefs.getStringList('favorite_players') ?? [];
    });
  }

  _toggleFavorite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isFavorite = !isFavorite;
    });

    List<String> favoriteTeams = prefs.getStringList('favoriteTeams') ?? [];
    if (isFavorite) {
      favoriteTeams.add(json.encode({
        'id': widget.club['id'],
        'name': widget.club['name'],
        'crestUrl': widget.club['crest'],
        'area': widget.club['area'],
      }));
    } else {
      favoriteTeams
          .removeWhere((team) => json.decode(team)['id'] == widget.club['id']);
    }
    await prefs.setStringList('favoriteTeams', favoriteTeams);
    print('Favorite teams updated: $favoriteTeams'); // Debug bilgisi
  }

  _toggleFavoritePlayer(String playerId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoritePlayers = prefs.getStringList('favoritePlayers') ?? [];

    final player = widget.club['squad']
        .firstWhere((p) => p['id'].toString() == playerId, orElse: () => null);

    if (player != null) {
      final playerJson = json.encode({
        'id': player['id'],
        'name': player['name'],
        'position': player['position'],
        'nationality': player['nationality'],
        'dateOfBirth': player['dateOfBirth'],
      });

      if (favoritePlayersIds.contains(playerId)) {
        favoritePlayersIds.remove(playerId);
        favoritePlayers.remove(playerJson);
      } else {
        favoritePlayersIds.add(playerId);
        favoritePlayers.add(playerJson);
      }

      await prefs.setStringList('favoritePlayers', favoritePlayers);
      await prefs.setStringList('favorite_players', favoritePlayersIds);

      setState(() {});
      print('Favorite players updated: $favoritePlayers'); // Debug bilgisi
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              backgroundColor: primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.club['name'] ?? 'Club Details',
                  style: TextStyle(
                      shadows: [Shadow(blurRadius: 5.0, color: Colors.black)]),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.club['crest'] ??
                          'https://via.placeholder.com/300x200',
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Icon(
                          Icons.sports_soccer,
                          size: 100,
                          color: secondaryColor),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            primaryColor.withOpacity(0.8)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white),
                  onPressed: _toggleFavorite,
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: _tabs.map((String name) => Tab(text: name)).toList(),
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: primaryColor,
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildSquadTab(),
            _buildMatchesTab(),
            _buildStatisticsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Club Information', [
            _buildInfoRow(Icons.sports_soccer, 'Name', widget.club['name']),
            _buildInfoRow(
                Icons.short_text, 'Short Name', widget.club['shortName']),
            _buildInfoRow(Icons.calendar_today, 'Founded',
                widget.club['founded']?.toString()),
            _buildInfoRow(Icons.stadium, 'Stadium', widget.club['venue']),
            _buildInfoRow(
                Icons.color_lens, 'Club Colors', widget.club['clubColors']),
          ]),
          SizedBox(height: 16),
          _buildInfoSection('Contact Information', [
            _buildInfoRow(Icons.web, 'Website', widget.club['website']),
            _buildInfoRow(Icons.email, 'Email', widget.club['email']),
            _buildInfoRow(Icons.phone, 'Phone', widget.club['phone']),
          ]),
          SizedBox(height: 16),
          _buildInfoSection('Address', [
            _buildInfoRow(Icons.location_on, 'Address', widget.club['address']),
          ]),
        ],
      ),
    );
  }

  Widget _buildSquadTab() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: (widget.club['squad'] ?? []).length,
      itemBuilder: (context, index) {
        final player = widget.club['squad'][index];
        final playerId = player['id'].toString();
        return GestureDetector(
          onTap: () => _showPlayerDetails(context, player),
          child: Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: secondaryColor,
                  child: Text(
                    (player['name'] ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  player['name'] ?? 'Unknown Player',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  player['position'] ?? 'Unknown Position',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text(
                  'Shirt: ${player['shirtNumber'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 14, color: primaryColor),
                ),
                IconButton(
                  icon: Icon(
                    favoritePlayersIds.contains(playerId)
                        ? Icons.star
                        : Icons.star_border,
                    color: favoritePlayersIds.contains(playerId)
                        ? Colors.yellow
                        : null,
                  ),
                  onPressed: () => _toggleFavoritePlayer(playerId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchesTab() {
    // This is a placeholder. You would need to fetch and display actual match data.
    return Center(child: Text('Match information not available'));
  }

  Widget _buildStatisticsTab() {
    // This is a placeholder. You would need to fetch and display actual statistics.
    return Center(child: Text('Statistics not available'));
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: secondaryColor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
                SizedBox(height: 4),
                Text(value ?? 'Unknown', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayerDetails(BuildContext context, Map<String, dynamic> player) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: PlayerDetailWidget(
              player: player,
              clubColor: primaryColor,
              clubName: widget.club['name']),
        ),
      ),
    );
  }
}

class PlayerDetailWidget extends StatelessWidget {
  final Map<String, dynamic> player;
  final Color clubColor;
  final String clubName;

  PlayerDetailWidget(
      {required this.player, required this.clubColor, required this.clubName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: clubColor,
                child: Text(
                  (player['name'] ?? '?')[0].toUpperCase(),
                  style: TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player['name'] ?? 'Unknown Player',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      player['position'] ?? 'Unknown Position',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 4),
                    Text(
                      clubName,
                      style: TextStyle(
                          fontSize: 16,
                          color: clubColor,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildPlayerInfoCard('Personal Information', [
            _buildPlayerInfoRow(
                'Nationality', player['nationality'] ?? 'Unknown', Icons.flag),
            _buildPlayerInfoRow('Date of Birth',
                _formatDate(player['dateOfBirth']), Icons.cake),
            _buildPlayerInfoRow(
                'Age', _calculateAge(player['dateOfBirth']), Icons.person),
          ]),
          SizedBox(height: 16),
          _buildPlayerInfoCard('Player Details', [
            _buildPlayerInfoRow(
                'Shirt Number',
                player['shirtNumber']?.toString() ?? 'N/A',
                Icons.sports_soccer),
            _buildPlayerInfoRow(
                'Position', player['position'] ?? 'Unknown', Icons.sports),
            _buildPlayerInfoRow(
                'Role', player['role'] ?? 'Unknown', Icons.work),
          ]),
          SizedBox(height: 16),
          _buildPlayerInfoCard('Contract Information', [
            _buildPlayerInfoRow(
                'Contract Until',
                _formatDate(player['contract']?['until']),
                Icons.calendar_today),
          ]),
          SizedBox(height: 24),
          Text(
            'Player Statistics',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: clubColor),
          ),
          SizedBox(height: 8),
          // Add player statistics here. This is a placeholder.
          Center(child: Text('Player statistics not available')),
        ],
      ),
    );
  }

  Widget _buildPlayerInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: clubColor),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: clubColor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d MMMM y').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null) return 'Unknown';
    try {
      final birthDate = DateTime.parse(dateOfBirth);
      final currentDate = DateTime.now();
      int age = currentDate.year - birthDate.year;
      if (currentDate.month < birthDate.month ||
          (currentDate.month == birthDate.month &&
              currentDate.day < birthDate.day)) {
        age--;
      }
      return '$age years';
    } catch (e) {
      return 'Unknown';
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
