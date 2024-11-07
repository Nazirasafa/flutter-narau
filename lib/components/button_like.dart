import 'dart:ui'; // Needed for ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class LikeButton extends StatefulWidget {
  final int postId;
  final bool isLiked;
  final int likeCount;

  const LikeButton({
    Key? key,
    required this.postId,
    required this.isLiked,
    required this.likeCount,
  }) : super(key: key);

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  final storage = const FlutterSecureStorage();
  late bool isLiked;
  late int likeCount;
  bool showLikeCount = false;

  @override
  void initState() {
    super.initState();
    isLiked = widget.isLiked;
    likeCount = widget.likeCount;
    showLikeCount = isLiked; // Show like count if initially liked
  }

  Future<void> likePost() async {
    final url = 'https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/posts/${widget.postId}/like';
    final authToken = await storage.read(key: 'auth_token');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $authToken',
        }
      );

      if (response.statusCode == 200) {
        setState(() {
          isLiked = true;
          likeCount += 1;
          showLikeCount = true;
        });
      } else {
        throw Exception('Failed to like the post');
      }
    } catch (e) {
        throw Exception('Error: $e');
    }
  }

  Future<void> unlikePost() async {
    final url = 'https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/posts/${widget.postId}/unlike';
    final authToken = await storage.read(key: 'auth_token');

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $authToken',
        }
      );

      if (response.statusCode == 200) {
        setState(() {
          isLiked = false;
          likeCount -= 1;
          showLikeCount = false;
        });
      } else {
        throw Exception('Failed to unlike the post');
      }
    } catch (e) {
        throw Exception('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Transform.translate(
        offset: const Offset(-16, 4),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.decelerate,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              width: showLikeCount ? 80 : 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.favorite,
                      color: isLiked ? Colors.pink : Colors.white,
                    ),
                    onPressed: () {
                      if (isLiked) {
                        unlikePost();
                      } else {
                        likePost();
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  AnimatedOpacity(
                    opacity: showLikeCount ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.decelerate,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        '$likeCount',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
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
