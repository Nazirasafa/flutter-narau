import 'package:api_frontend/screens/event/event_detail.dart';
import 'package:api_frontend/screens/home/home_profile.dart';
import 'package:api_frontend/screens/news/news_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final storage = const FlutterSecureStorage();
  String fullName = '';
  String profilePic = '';
  String email = '';
  bool _isImageVisible = false;


  List<dynamic> posts = [];
  List<dynamic> events = [];

  bool postIsLoading = true;
  bool eventIsLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
    fetchPosts();
    fetchEvents();
    Future.delayed(Duration(milliseconds: 50), () {
      setState(() {
        _isImageVisible = true;
      });
    });
  }

  Future<void> _navigateToProfile() async {
    final bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(name: fullName, email: email, profilePic: profilePic)),
    );

    if (updated == true) {
      await loadUserData(); // Reload user data if profile was updated
    }
  }

  Future<void> loadUserData() async {
    final name = await storage.read(key: 'name') ?? '';
    final pic = await storage.read(key: 'profile_pic') ?? '';
    final emailStorage = await storage.read(key: 'email') ?? '';

    setState(() {
      email = emailStorage;
      fullName = name;
      profilePic = pic;
    });
  }

  Future<void> fetchPosts() async {
    final response = await http.get(Uri.parse(
        'http://10.0.2.2:8000/api/latest/posts'));
    if (response.statusCode == 200) {
      setState(() {
        posts = json.decode(response.body)['data'];
      });
      postIsLoading = false;
    }
  }

  Future<void> fetchEvents() async {
    final response = await http.get(Uri.parse(
        'http://10.0.2.2:8000/api/latest/events'));
    if (response.statusCode == 200) {
      setState(() {
        events = json.decode(response.body)['data'];
      });
      eventIsLoading = false;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: AnimatedOpacity(
        opacity: _isImageVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 600),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child:  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hello,',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Hi $fullName',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          _navigateToProfile();
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: profilePic.isNotEmpty
                                  ? CachedNetworkImageProvider(profilePic)
                                  : const AssetImage(
                                          'assets/profile_placeholder.png')
                                      as ImageProvider,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  ),

                
                  // Recent News Section
                  const Text(
                    'Recent News',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // News Grid
                  SizedBox(
                    height: 230, // Increased height for the horizontal list
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailNewsScreen(postId: post['id']),
                              ),
                            );
                          },
                          child: Container(
                            width: 200, // Increased width for each item
                            margin: const EdgeInsets.only(right: 10), // Add spacing between items
                            padding: const EdgeInsets.all(8.0), // Added padding inside the card
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image(
                                    image: CachedNetworkImageProvider(post['img']),
                                    fit: BoxFit.cover,
                                    height: 120, // Adjusted height for the image
                                    width: double.infinity,
                                  ),
                                ),
                                const SizedBox(height: 8), // Space between image and text
                                Expanded( // Use Expanded to prevent overflow
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4.0), // Padding for text
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post['title'],
                                          style: const TextStyle(
                                            fontSize: 16, // Increased font size
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${post['read_time']} min read',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Upcoming Events Section
                  const Text(
                    'Upcoming Events',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length > 3 ? 3 : events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailScreen(event: event),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Date component - made bigger
                              Center(
                                child: Text(
                                  DateFormat('d MMMM').format(DateTime.parse(event['date'])),
                                  style: const TextStyle(
                                    fontSize: 32, // Increased font size for the date
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4), // Space between date and event name
                              // Event name component
                              Center(
                                child: Text(
                                  event['name'],
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16, // Font size for the event name
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
