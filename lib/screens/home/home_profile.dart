import 'package:api_frontend/login.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart'; // Use image_picker 1.0+
import 'dart:io'; // For File class

class ProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String profilePic;

  ProfileScreen({
    required this.name,
    required this.email,
    required this.profilePic,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final storage = const FlutterSecureStorage();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  String? _newProfilePic;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  Future<void> _logout() async {
    final authToken = await storage.read(key: 'auth_token');
    const url =
        'https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/logout';

    try {
      final response = await Dio().post(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        await storage.deleteAll();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        throw Exception('Logout failed');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _newProfilePic = pickedFile.path;
      });
    }
  }

  Future<void> _handleProfileUpdate() async {
    setState(() => _isLoading = true);

    try {
      final authToken = await storage.read(key: 'auth_token');
      print(
          'Auth Token: $authToken'); // Debug print to check if token is retrieved

      final response = await updateProfile(
        authToken: authToken!,
        name: _nameController.text,
        email: _emailController.text,
        profilePic: _newProfilePic,
      );

      print(
          'Profile update response: $response'); // Debug print to inspect the response

      if (response['success']) {
        await storage.write(
            key: 'name', value: response['data']['data']['user']['name']);
        await storage.write(
            key: 'email', value: response['data']['data']['user']['email']);
        await storage.write(
            key: 'profile_pic', value: response['data']['data']['profile_pic']);

        if (mounted) {
          print(
              "Profile update successful, returning true"); // Check if pop is executed with true
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      print("Error: $e"); // Print error if any occurs
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
                        ? FileImage(File(_newProfilePic!))
                        : widget.profilePic.isNotEmpty
                            ? CachedNetworkImageProvider(widget.profilePic)
                            : const AssetImage('assets/profile_placeholder.png')
                                as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
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
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _isLoading
                  ? null
                  : _handleProfileUpdate, // Fix: Call the function
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Update Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _logout, // Fix: Call the function
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>> updateProfile({
  required String authToken,
  required String name,
  required String email,
  String? profilePic,
}) async {
  final dio = Dio();
  const url =
      'https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/profile/update?_method=PUT';

  final formData = FormData.fromMap({
    'name': name,
    'email': email,
    if (profilePic != null)
      'profile_pic': await MultipartFile.fromFile(profilePic),
  });

  try {
    print("Sending profile update request with data: $formData");

    final response = await dio.post(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      ),
      data: formData,
    );

    print("Profile update response status: ${response.statusCode}");
    print("Profile update response data: ${response.data}");

    if (response.statusCode == 200) {
      return {'success': true, 'data': response.data};
    } else {
      print('Failed to update profile. Status code: ${response.statusCode}');
      return {'success': false, 'message': 'Failed to update profile'};
    }
  } catch (e) {
    print("Error occurred while updating profile: $e");
    return {
      'success': false,
      'message': 'Error occurred while updating profile'
    };
  }
}
