import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // JSON desteği için
import 'home.dart'; // Ana sayfa dosyanızı import edin
import 'pincode.dart'; // Pincode sayfasını import edin

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // JSON verisini çek ve yönlendirme yap
    fetchScreenData();
  }

  Future<void> fetchScreenData() async {
    // JSON verisini çek
    final response = await http
        .get(Uri.parse('https://appledeveloper.com.tr/screen/screen.json'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      int screen = data['screen'];

      // Belirtilen süre bekleyip yönlendirme yap
      Future.delayed(Duration(seconds: 3), () {
        if (screen == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else if (screen == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PinCodeScreen()),
          );
        }
      });
    } else {
      // Hata durumunda ana sayfaya yönlendirme
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_football,
              size: 80.0,
              color: Colors.white,
            ),
            SizedBox(height: 20.0),
            Text(
              'Fubi Community',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20.0),
            SpinKitFadingCircle(
              color: Colors.white,
              size: 50.0,
            ),
          ],
        ),
      ),
    );
  }
}
