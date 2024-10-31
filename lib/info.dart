import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  _InfoScreenState createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  List<dynamic> postList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final response =
        await http.get(Uri.parse('http://10.0.2.2:8000/api/posts'));

    if (response.statusCode == 200) {
      setState(() {
        postList = json.decode(response.body)['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load posts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Info',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFA594F9)))
          : ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: postList.length,
              itemBuilder: (context, index) {
                final post = postList[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetailInfoScreen(postId: post['id']),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['title'] ?? 'No Title',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            post['body'] ?? 'No Description',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class DetailInfoScreen extends StatefulWidget {
  final int postId;

  const DetailInfoScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _DetailInfoScreenState createState() => _DetailInfoScreenState();
}

class _DetailInfoScreenState extends State<DetailInfoScreen> {
  Map<String, dynamic>? post;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPostDetail();
  }

  Future<void> fetchPostDetail() async {
    final response = await http
        .get(Uri.parse('http://10.0.2.2:8000/api/posts/${widget.postId}'));

    if (response.statusCode == 200) {
      setState(() {
        post = json.decode(response.body)['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load post details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(post?['title'] ?? 'Detail Info'),
        backgroundColor: Color(0xFFA594F9),
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFA594F9)))
          : post == null
              ? Center(
                  child: Text('No post found.', style: TextStyle(fontSize: 18)))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Carousel for images
                      if (post!['images'] != null && post!['images'].isNotEmpty)
                        Container(
                          height: 250,
                          child: PageView.builder(
                            itemCount: post!['images'].length,
                            itemBuilder: (context, index) {
                                  final image = post!['images'][index];
                                  return ClipRRect(
                                    child: CachedNetworkImage(
                                      imageUrl: image['image'],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFA594F9),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Icon(
                                        Icons.error,
                                        size: 50,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  );
                                },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post!['title'] ?? 'No Title',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFA594F9)),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Views: ${post!['views'] ?? 0}',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[700]),
                            ),
                            SizedBox(height: 16),
                            Text(
                              post!['body'] ?? 'No description available',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black87),
                            ),
                            // More sections can be added here for categories, comments, etc.
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
