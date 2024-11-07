import 'dart:ui';

import 'package:api_frontend/screens/news/news_filtered.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:api_frontend/components/button_like.dart';

class DetailNewsScreen extends StatefulWidget {
  final int postId;
  const DetailNewsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _DetailNewsScreenState createState() => _DetailNewsScreenState();
}

class _DetailNewsScreenState extends State<DetailNewsScreen> {
  final storage = const FlutterSecureStorage();
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  late Future<Map<String, dynamic>> _postDetails;

  @override
  void initState() {
    super.initState();
    _postDetails = fetchPostDetails(); // Load data on widget initialization
  }

  Future<Map<String, dynamic>> fetchPostDetails() async {
    final userId = await storage.read(key: 'userid');

    final response = await http.post(
        Uri.parse(
            'https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/posts/${widget.postId}'),
        body: {'user_id': userId});
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Failed to load post details');
    }
  }

  Future<void> _sendComment() async {
    final authToken = await storage.read(key: 'auth_token');
    final name = await storage.read(key: 'name') ?? '';

    if (_commentController.text.isEmpty) return;
    setState(() {
      _isSubmitting = true;
    });

    final response = await http.post(
        Uri.parse(
            'https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/posts/${widget.postId}/comment'),
        body: {
          'name': name,
          'text': _commentController.text
        },
        headers: {
          'Authorization': 'Bearer $authToken',
        });

    if (response.statusCode == 200) {
      setState(() {
        _commentController.clear();
        _isSubmitting = false;
        _postDetails =
            fetchPostDetails(); // Reload post details including new comments
      });
    } else {
      setState(() {
        _isSubmitting = false;
      });
      throw Exception('Failed to send comment');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchPostDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final post = snapshot.data!;
            final comments = post['comments'] as List<dynamic>;
            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 300,
                      floating: false,
                      pinned: false,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Hero(
                              tag: 'post-${post['id']}',
                              child: CachedNetworkImage(
                                imageUrl: post['img'],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                            // Overlay dengan efek fading hitam dari atas
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors
                                        .black54, // Hitam semi-transparan di bagian atas
                                    Colors
                                        .transparent, // Transparan di bagian bawah
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      leading: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Transform.translate(
                          offset: const Offset(16, 4),
                          child: ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(20)),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(20)),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  color: Colors.white,
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        LikeButton(
                          postId: post['id'],
                          isLiked: post['isLiked'],
                          likeCount: post['likes'],
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 280,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    padding:
                        const EdgeInsets.only(right: 30, left: 30, bottom: 80),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 30),
                          Wrap(
                            spacing: 6.0,
                            children:
                                post['categories'].map<Widget>((category) {
                              return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FilteredNewsScreen(
                                                category: category['title']),
                                      ),  
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      category['title'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ));
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            post['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                             const CircleAvatar(
                                  radius: 20,
                                  backgroundImage: AssetImage(
                                      'assets/profile_placeholder.png'), // Local asset
                                ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${post['user']['name']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${post['read_time']} min read',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            post['body'] ?? '',
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 26),

                          // Comments Section
                          const Text('Comments',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 20),
                          for (var comment in comments) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundImage: AssetImage(
                                      'assets/profile_placeholder.png'), // Local asset
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment['name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(comment['text']),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(
                        left: 24, right: 24, top: 10, bottom: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 5,
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Write a comment...',
                                hintStyle: TextStyle(color: Colors.grey[700]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _sendComment,
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(15),
                            backgroundColor: Colors.blue,
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Icon(Icons.send, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
