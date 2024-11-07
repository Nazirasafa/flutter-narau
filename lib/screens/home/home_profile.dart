import 'package:api_frontend/login.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart'; // Use image_picker 1.0+
import 'dart:io'; // For File class

class ProfileScreen extends StatefulWidget {
  final String name;
  final String profilePic;

  ProfileScreen({
    required this.name,
    required this.profilePic,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final storage = const FlutterSecureStorage();
  late TextEditingController _nameController;
  String? _newProfilePic;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    print('Auth Token: $authToken');
    
    final response = await updateProfile(
      authToken: authToken!,
      name: _nameController.text,
      profilePic: _newProfilePic,
    );

    print('Profile update response: $response');

    if (response['success']) {
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      throw Exception('Failed to update profile');
    }
  } catch (e) {
    print("Error: $e");
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
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleProfileUpdate,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.all(10)),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Update Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    shadowColor: Colors.black,
                    padding: const EdgeInsets.all(10)),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
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
// Extracted method to handle profile update request
Future<Map<String, dynamic>> updateProfile({
  required String authToken,
  required String name,
  String? profilePic,
}) async {
  final dio = Dio();
  const url = 'https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/api/profile/update?_method=PUT';
  

  // Debug print to check if profilePic is not null and correct
  if (profilePic != null) {
    print('Profile Picture Path: $profilePic');
  } else {
    print('No profile picture selected.');
  }

  final formData = FormData.fromMap({
    'name': name,
    if (profilePic != null) 'profile_pic': await MultipartFile.fromFile(profilePic),
  });

  try {
    print('Sending update profile request...');
    print('URL: $url');
    print('Headers: {Authorization: Bearer $authToken}');
    print('FormData: $formData');

    final response = await dio.post(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      ),
      data: formData,
    );

    print('Response status code: ${response.statusCode}');
    print('Response data: ${response.data}');
    
    if (response.statusCode == 200) {
      return {'success': true, 'data': response.data};
    } else {
      print('Failed to update profile. Status code: ${response.statusCode}');
      return {'success': false, 'message': 'Failed to update profile'};
    }
  } catch (e) {
    print("Error occurred while updating profile: $e");
    return {'success': false, 'message': 'Error occurred while updating profile'};
  }
}
