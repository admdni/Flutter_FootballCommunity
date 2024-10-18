import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

class BottomNavBar extends StatelessWidget {
  final int activeIndex;
  final Function(int) onTap;

  BottomNavBar({required this.activeIndex, required this.onTap});

  final List<IconData> iconList = [
    Icons.nature,
    Icons.search,
    Icons.favorite,
    Icons.social_distance,
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavigationBar(
      icons: iconList,
      activeIndex: activeIndex,
      gapLocation: GapLocation.center,
      notchSmoothness: NotchSmoothness.verySmoothEdge,
      leftCornerRadius: 32,
      rightCornerRadius: 32,
      onTap: onTap,
      backgroundColor: Colors.green,
      activeColor: Colors.white,
      inactiveColor: Colors.white.withOpacity(0.5),
      iconSize: 24,
    );
  }
}
