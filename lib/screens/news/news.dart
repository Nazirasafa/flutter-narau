import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:api_frontend/screens/news/news_detail.dart';
import 'package:api_frontend/screens/news/news_category.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';



class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<dynamic> postList = [];
  List<dynamic> filteredPostList = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final storage = const FlutterSecureStorage();


  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final authToken = await storage.read(key: 'auth_token');
    try {
      final response = await http.get(Uri.parse(
        'https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/posts'),
        headers: {
        'Authorization': 'Bearer $authToken',
      },);
      if (response.statusCode == 200) {
        setState(() {
          postList = json.decode(response.body)['data'];
          filteredPostList = postList;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Failed to load events: $e');
    }
  }

  void searchPosts(String query) {
    setState(() {
      searchQuery = query;
      filteredPostList = postList
          .where((post) =>
              post['title'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'News',
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'News about SMKN 4 Bogor',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 3,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: searchPosts,
                      decoration: InputDecoration(
                        hintText: 'Search..',
                        prefixIcon: Icon(
                          Icons.search,
                          size: 25,
                          color: Colors.grey[500],
                        ),
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 15,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[400],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Text(
                              'All News',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 3,
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Other Categories..',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : postList.isEmpty
                      ? const Center(child: Text('No posts found in this category'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredPostList.length,
                          itemBuilder: (context, index) {
                            final post = filteredPostList[index];
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
                                  padding: const EdgeInsets.all(15.0),
                                  margin: const EdgeInsets.only(top: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        const BorderRadius.all(Radius.circular(30)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 5,
                                        blurRadius: 15,
                                        offset: const Offset(
                                            0, 3), // changes position of shadow
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Hero(
                                            tag: 'post-${post['id']}',
                                            child: CachedNetworkImage(
                                              imageUrl: post['img'],
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                color: Colors.grey[300],
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                spacing:
                                                    6.0, // Spacing between each category
                                                children: post['categories']
                                                    .map<Widget>((category) {
                                                  return Text(
                                                    category['title'] ?? '',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.blue,
                                                      fontSize: 12,
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                post['title'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  height:
                                                      1.0, // Atur nilai height sesuai kebutuhan
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Text(
                                                    post['user']['name'],
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.grey[500],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    ' • ${post['read_time']} min read',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.grey[500],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                
                                ));
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

