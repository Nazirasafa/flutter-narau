import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

// Widget wrapper untuk lazy loading image
class LazyLoadImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const LazyLoadImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      placeholder: (context, url) => ShimmerLoading(
        width: width,
        height: height,
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(
          Icons.error_outline,
          color: Colors.red,
        ),
      ),
    );
  }
}

// Widget untuk efek loading menggunakan Shimmer
class ShimmerLoading extends StatelessWidget {
  final double? width;
  final double? height;

  const ShimmerLoading({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    );
  }

  
}

class LazyLoadContainer extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final Widget? child;

  const LazyLoadContainer({
    Key? key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = 25,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        image: DecorationImage(
          image: CachedNetworkImageProvider(
            imageUrl,
            maxWidth: 800, // Atur sesuai kebutuhan
            maxHeight: 800, // Atur sesuai kebutuhan
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}

// Contoh penggunaan dalam widget
class ExampleGalleryItem extends StatelessWidget {
  final Map<String, dynamic> gallery;

  const ExampleGalleryItem({
    Key? key,
    required this.gallery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LazyLoadContainer(
      imageUrl: gallery['img'],
      width: double.infinity,
      height: 200,
      borderRadius: 25,
    );
  }
}


