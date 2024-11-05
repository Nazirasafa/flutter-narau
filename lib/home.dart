import 'package:api_frontend/event.dart';
import 'package:api_frontend/login.dart';
import 'package:api_frontend/news.dart';
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
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

   Future<void> updateProfile() async {
    final authToken = await storage.read(key: 'auth_token');
    if (authToken == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    final url = Uri.parse('http://10.0.2.2:8000/api/profile/update');
    final response = await http.put(
      url,
      body: {
        'name': fullName,
        //'profile_pic': profilePic,
      },
      headers: {
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      print('updating profile: ${response.body}');

      // Update the local data and refresh the UI
      loadUserData();
    } else {
      // Handle the error case
      print('Error updating profile: ${response.statusCode}');
    }
  }

  Future<void> fetchPosts() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/latest/posts'));
    if (response.statusCode == 200) {
      setState(() {
        posts = json.decode(response.body)['data'];
      });
      postIsLoading = false;
    }
  }

  Future<void> fetchEvents() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/latest/events'));
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
                                onProfileUpdate: updateProfile,
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
                                  : const AssetImage('assets/profile_placeholder.png') as ImageProvider,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // User Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
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
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
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
                                builder: (context) => DetailNewsScreen(postId: post['id']),
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
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
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
                                        style: const TextStyle(color: Colors.white70),
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
                              builder: (context) => EventDetailScreen(event: event),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event['name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  event['short_desc'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('EEEE, d MMMM').format(DateTime.parse(event['date'])),
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${DateFormat('HH:mm').format(DateTime.parse('2024-01-01 ${event['time_start']}'))} - '
                                      '${DateFormat('HH:mm').format(DateTime.parse('2024-01-01 ${event['time_end']}'))}',
                                      style: const TextStyle(color: Colors.grey),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final String name;
  final String profilePic;
  final VoidCallback onProfileUpdate;

  ProfileScreen({
    required this.name,
    required this.profilePic,
    required this.onProfileUpdate,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late String _profilePic;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _profilePic = widget.profilePic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateProfile() {
    // Update the profile data and call the callback
    widget.onProfileUpdate();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profilePic.isNotEmpty
                        ? CachedNetworkImageProvider(_profilePic)
                        : const AssetImage('assets/profile_placeholder.png') as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // Add logic to update profile picture
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}