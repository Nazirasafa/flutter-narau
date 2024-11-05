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

    final url = Uri.parse('http://10.0.2.2:8000/api/profile/update');

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
    } else {
      print('Error updating profile: ${response.statusCode}');
    }
  }

  Future<void> fetchPosts() async {
    final response =
        await http.get(Uri.parse('http://10.0.2.2:8000/api/latest/posts'));
    if (response.statusCode == 200) {
      setState(() {
        posts = json.decode(response.body)['data'];
      });
      postIsLoading = false;
    }
  }

  Future<void> fetchEvents() async {
    final response =
        await http.get(Uri.parse('http://10.0.2.2:8000/api/latest/events'));
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
                                  : const AssetImage(
                                          'assets/profile_placeholder.png')
                                      as ImageProvider,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

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
                            margin: const EdgeInsets.only(bottom: 16),
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
                                const SizedBox(height: 8),

                                // Date and Time row
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: Colors.grey[600],
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('EEEE, d MMMM').format(
                                          DateTime.parse(event['date'])),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.access_time,
                                      color: Colors.grey[600],
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${event['time_start']} - ${event['time_end']}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
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

class ProfileScreen extends StatefulWidget {
  final String name;
  final String profilePic;
  final Function(String newName, String? newProfilePic) onProfileUpdate;

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
  String? _newProfilePic;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      await widget.onProfileUpdate(
        _nameController.text,
        _newProfilePic,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
                    backgroundImage: _newProfilePic != null
                        ? CachedNetworkImageProvider(_newProfilePic!)
                        : widget.profilePic.isNotEmpty
                            ? CachedNetworkImageProvider(widget.profilePic)
                            : const AssetImage('assets/profile_placeholder.png')
                                as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () async {
                        // Add your image picking logic here
                        // Example:
                        // final picker = ImagePicker();
                        // final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        // if (pickedFile != null) {
                        //   setState(() {
                        //     _newProfilePic = pickedFile.path;
                        //   });
                        // }
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
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Update Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
