import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';

class GalleryDetailScreen extends StatefulWidget {
  final int galleryId;

  const GalleryDetailScreen({super.key, required this.galleryId});

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
      final response = await http.get(Uri.parse(
          'http://10.0.2.2:8000/api/galleries/${widget.galleryId}'));

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.deepPurple,
                  onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFA594F9)),
            )
          : gallery == null
              ? const Center(child: Text('No data available'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gallery Header Image
                      Hero(
                        tag: 'gallery-${gallery!['id']}',
                        child: CachedNetworkImage(
                          imageUrl: gallery!['img'] ?? '',
                          fit: BoxFit.cover,
                          height: 300,
                          width: double.infinity,
                          placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                      
                      // Content Container
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(50),
                            topRight: Radius.circular(50),
                          ),
                        ),
                        padding: const EdgeInsets.only(
                            right: 30, left: 30, bottom: 30),
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
                            // Created At Section
                            const SizedBox(height: 8),
                            Text(
                              'Created: ${gallery!['created_at'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
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
                            GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    MediaQuery.of(context).size.width > 600
                                        ? 4
                                        : 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1 / 1,
                              ),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: images.length,
                              itemBuilder: (context, index) {
                                final imageUrl = images[index]['image'];

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            GestureDetector(
                                          onTap: () => Navigator.pop(context),
                                          child: Scaffold(
                                            backgroundColor: Colors.white,
                                            body: Center(
                                              child: Hero(
                                                tag:
                                                    'imageHero-$imageUrl',
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8),
                                                  child: CachedNetworkImage(
                                                    imageUrl: imageUrl,
                                                    fit: BoxFit.contain,
                                                    placeholder: (context,
                                                            url) =>
                                                        const Center(
                                                            child:
                                                                CircularProgressIndicator()),
                                                    errorWidget: (context,
                                                            url, error) =>
                                                        const Icon(
                                                            Icons.error),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        transitionsBuilder: (context,
                                            animation,
                                            secondaryAnimation,
                                            child) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Hero(
                                    tag: 'imageHero-$imageUrl',
                                    child: Container(
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.grey.withOpacity(0.4),
                                            spreadRadius: 3,
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                        borderRadius:
                                            BorderRadius.circular(8),
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
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}