import 'package:api_frontend/components/lazyloadimage.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<Map<String, dynamic>> galleryList = [];
  List<Map<String, dynamic>> filteredGallery = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchGallery();
  }

  Future<void> fetchGallery() async {
    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:8000/api/galleries'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List;
        setState(() {
          galleryList =
              data.map((item) => item as Map<String, dynamic>).toList();
          filteredGallery = galleryList;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load gallery');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Failed to load gallery: $e');
    }
  }

  void searchGallery(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredGallery = galleryList;
      } else {
        filteredGallery = galleryList
            .where((item) => item['name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
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
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Galleries',
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Delve into the diverse galleries of SMKN 4 Bogor.',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSearchBar(),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: const CircularProgressIndicator(
                        color: const Color(0xFFA594F9)))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWideScreen ? 3 : 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 3 / 4,
                    ),
                    itemCount: filteredGallery.length,
                    itemBuilder: (context, index) {
                      final gallery = filteredGallery[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GalleryDetailScreen(galleryId: gallery['id']),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.4),
                                spreadRadius: 3,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(25),
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(
                                gallery['img'],
                                maxWidth: 800,
                                maxHeight: 800,
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(
                                  gallery['name'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
        onChanged: searchGallery,
        decoration: InputDecoration(
          hintText: 'Search..',
          prefixIcon: Icon(
            Icons.search,
            size: 25,
            color: Colors.grey[500],
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[500]),
                  onPressed: () {
                    _searchController.clear();
                    searchGallery('');
                  },
                )
              : null,
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }
}

class GalleryDetailScreen extends StatefulWidget {
  final int galleryId;

  const GalleryDetailScreen({Key? key, required this.galleryId})
      : super(key: key);

  @override
  _GalleryDetailScreenState createState() => _GalleryDetailScreenState();
}

class _GalleryDetailScreenState extends State<GalleryDetailScreen> {
  Map<String, dynamic>? gallery;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGalleryDetail();
  }

  Future<void> fetchGalleryDetail() async {
    try {
      final response = await http.get(
          Uri.parse('http://10.0.2.2:8000/api/galleries/${widget.galleryId}'));

      if (response.statusCode == 200) {
        setState(() {
          gallery = json.decode(response.body)['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load gallery details');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading gallery details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = gallery?['images'] ?? [];
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFA594F9)),
            )
          : gallery == null
              ? const Center(child: Text('No data available'))
              : Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          expandedHeight: 300,
                          floating: false,
                          pinned: false,
                          flexibleSpace: FlexibleSpaceBar(
                            background: Hero(
                              tag: 'gallery-${gallery!['id']}',
                              child: CachedNetworkImage(
                                imageUrl: gallery!['img'] ?? '',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                          ),
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
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
                        padding: const EdgeInsets.only(
                            right: 30, left: 30, bottom: 30),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 30),
                              Text(
                                gallery!['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                gallery!['desc'] ?? '',
                                textAlign: TextAlign.justify,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                ),
                              ),
                               const SizedBox(height: 26),
                              const Text(
                                'Images',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      MediaQuery.of(context).size.width > 600
                                          ? 4
                                          : 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 3 / 4,
                                ),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: images.length,
                                itemBuilder: (context, index) {
                                  final imageUrl = images[index]['image'];

                                  return GestureDetector(
                                    onTap: () {
                                      // Aksi ketika gambar ditekan, jika diperlukan.
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.4),
                                            spreadRadius: 3,
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                        borderRadius: BorderRadius.circular(25),
                                        image: DecorationImage(
                                          image: CachedNetworkImageProvider(
                                            imageUrl,
                                            maxWidth: 800,
                                            maxHeight: 800,
                                          ),
                                          fit: BoxFit.cover,
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
                  ],
                ),
    );
  }

  
}
