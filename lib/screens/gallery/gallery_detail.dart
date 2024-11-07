import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';

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
      final response = await http.get(Uri.parse(
          'https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/galleries/${widget.galleryId}'));

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
                            background: Stack(
                              fit: StackFit.expand,
                              children: [
                                Hero(
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
                                  filter: ImageFilter.blur(
                                      sigmaX: 8.0, sigmaY: 8.0),
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
                                style: TextStyle(
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
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation,
                                                  secondaryAnimation) =>
                                              GestureDetector(
                                            onTap: () => Navigator.pop(
                                                context), // Tutup modal jika ditekan
                                            child: Scaffold(
                                              backgroundColor: Colors.white,
                                              body: Center(
                                                child: Hero(
                                                  tag:
                                                      'imageHero-$imageUrl', // Tag Hero unik untuk animasi
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20), // Border radius untuk rounded
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
                                      tag:
                                          'imageHero-$imageUrl', // Pastikan tag ini sama dengan di modal
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
                                              BorderRadius.circular(25),
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
                      ),
                    ),
                  ],
                ),
    );
  }
}
