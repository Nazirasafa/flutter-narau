import 'package:api_frontend/gallery.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'news.dart';
import 'event.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    HomeScreen(),
    const NewsScreen(),
    EventScreen(),
    const GalleryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
   Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar:
       Padding(
        padding: const EdgeInsets.only(right: 20.0, left: 20.0,  bottom: 20.0, top: 10),
        child: PhysicalModel(
          color: Colors.white,
          elevation: 0,
          borderRadius: BorderRadius.circular(30.0),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 15,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.home, index: 0, label: "Home"),
                _buildNavItem(icon: Icons.info, index: 1, label: "News"),
                _buildNavItem(icon: Icons.person, index: 2, label: "Event"),
                _buildNavItem(icon: Icons.article, index: 3, label: "Gallery"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index, required String label}) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : const Color.fromARGB(255, 122, 195, 255),
          size: 26,
        ),
      ),
    );
  }
}