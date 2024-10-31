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
  List<dynamic> galleryList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGallery();
  }

  Future<void> fetchGallery() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/galleries'));

    if (response.statusCode == 200) {
      setState(() {
        galleryList = json.decode(response.body)['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load gallery');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gallery',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFA594F9)))
          : GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWideScreen ? 2 : 1, // Single column on small screens
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 16 / 6, // Set to 16:9 aspect ratio
              ),
              itemCount: galleryList.length,
              itemBuilder: (context, index) {
                final gallery = galleryList[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GalleryDetailScreen(galleryId: gallery['id']), // Pass the gallery ID here
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: gallery['img'] ?? 'https://via.placeholder.com/150',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFA594F9),
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(Icons.error, size: 50, color: Colors.redAccent),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gallery['name'] ?? 'No Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  gallery['desc'] ?? 'No Description',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
    );
  }
}

class GalleryDetailScreen extends StatefulWidget {
  final int galleryId;

  const GalleryDetailScreen({Key? key, required this.galleryId}) : super(key: key);

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
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/galleries/${widget.galleryId}'));

    if (response.statusCode == 200) {
      setState(() {
        gallery = json.decode(response.body)['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load gallery details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(gallery?['name'] ?? 'Gallery Detail'),
        backgroundColor: Color(0xFFA594F9),
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFA594F9)))
          : gallery == null
              ? Center(child: Text('No gallery found.', style: TextStyle(fontSize: 18)))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: gallery!['img'] ?? 'https://via.placeholder.com/300',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFA594F9),
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(Icons.error, size: 50, color: Colors.redAccent),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gallery!['name'] ?? 'No Name',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFA594F9)),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Posted on: ${gallery!['created_at'] ?? 'Unknown Date'}',
                              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                            ),
                            SizedBox(height: 16),
                            Text(
                              gallery!['desc'] ?? 'No description available',
                              style: TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      if (gallery!['images'] != null && gallery!['images'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('More Photos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      if (gallery?['images'] != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2, // Adjust for screen size
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: gallery!['images'].length,
                            itemBuilder: (context, index) {
                              final image = gallery!['images'][index];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: image['image'],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFA594F9),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Icon(Icons.error, size: 50, color: Colors.redAccent),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
