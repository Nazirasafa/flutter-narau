import 'package:api_frontend/screens/event/event_detail.dart';
import 'package:api_frontend/screens/home/home_profile.dart';
import 'package:api_frontend/login.dart';
import 'package:api_frontend/screens/news/news_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final storage = const FlutterSecureStorage();
  String userName = '';
  String fullName = '';
  String profilePic = '';
  List<dynamic> posts = [];
  List<dynamic> events = [];
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  bool postIsLoading = true;
  bool eventIsLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
    fetchPosts();
    fetchEvents();
    _initAnimation();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  Future<void> loadUserData() async {
    final name = await storage.read(key: 'name') ?? '';
    //final pic = await storage.read(key: 'profile_pic') ?? '';
    setState(() {
      fullName = name;
      userName = name.split(' ')[0];
      //profilePic = pic;
    });
  }

  Future<void> updateProfile(String newName, String? newProfilePic) async {
    final authToken = await storage.read(key: 'auth_token');
    if (authToken == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    final url = Uri.parse(
        'https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/profile/update');

    final Map<String, String> body = {
      'name': newName,
    };

    if (newProfilePic != null) {
      body['profile_pic'] = newProfilePic;
    }

    final response = await http.put(
      url,
      body: body,
      headers: {
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      // Update the local storage with new values
      await storage.write(key: 'name', value: newName);
      if (newProfilePic != null) {
        await storage.write(key: 'profile_pic', value: newProfilePic);
      }

      // Reload the user data to refresh the UI
      await loadUserData();
    } else {}
  }

  Future<void> fetchPosts() async {
    final response = await http.get(Uri.parse(
        'https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/latest/posts'));
    if (response.statusCode == 200) {
      setState(() {
        posts = json.decode(response.body)['data'];
      });
      postIsLoading = false;
    }
  }

  Future<void> fetchEvents() async {
    final response = await http.get(Uri.parse(
        'https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/latest/events'));
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
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(26.0),
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
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
                            'Hi $userName',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(
                                name: fullName,
                                profilePic: profilePic,
                              ),
                            ),
                          );
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
                  const SizedBox(height: 26),

                  // User Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Guest',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            Text(
                              DateFormat('MMMM d, yyyy').format(DateTime.now()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Recent Section
                  const Text(
                    'Recent News',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // News Carousel
                  if (posts.isNotEmpty)
                    CarouselSlider.builder(
                      itemCount: posts.length,
                      options: CarouselOptions(
                        height: 200,
                        viewportFraction: 1,
                        enlargeCenterPage: true,
                        autoPlay: true,
                      ),
                      itemBuilder: (context, index, realIndex) {
                        final post = posts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailNewsScreen(postId: post['id']),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(post['img']),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.8)
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        '${post['read_time']} min read',
                                        style: const TextStyle(
                                            color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 30),

                  // Upcoming Events Section
                  const Text(
                    'Upcoming Events',
                    style: TextStyle(
                      fontSize: 20,
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
                                builder: (context) =>
                                    EventDetailScreen(event: event),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 3,
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title of the event
                                Center(
                                  child: Text(
                                    event['name'],
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                // Short description of the event
                                Center(
                                  child: Text(
                                    event['short_desc'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            color: Colors.white,
                                            size: 16,
                                            weight: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            DateFormat('EEEE, d MMMM').format(
                                                DateTime.parse(event['date'])),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ],
                                ),
                              ],
                            ),
                          ));
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
