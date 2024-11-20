import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'dart:convert';

class AddPostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final storage = FlutterSecureStorage();
  bool isLoading = true;
  List<dynamic> categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://secretly-immortal-ghoul.ngrok-free.app/api/categories')
      );
      if (response.statusCode == 200) {
        setState(() {
          categories = json.decode(response.body)['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  TextEditingController _titleController = TextEditingController();
  TextEditingController _bodyController = TextEditingController();
  TextEditingController _readTimeController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  List<int> _selectedCategories = [];

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String? userId = await storage.read(key: 'userid');
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      final token = await storage.read(key: 'auth_token');
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('https://secretly-immortal-ghoul.ngrok-free.app/api/posts')
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      request.fields['title'] = _titleController.text;
      request.fields['body'] = _bodyController.text;
      
         _selectedCategories.asMap().forEach((index, categoryId) {
      request.fields['category_ids[$index]'] = categoryId.toString();
    });
      request.fields['user_id'] = userId;
      request.fields['read_time'] = _readTimeController.text;

      if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'img', 
          _selectedImage!.path
        ));
      }
      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post created successfully')),
        );
        Navigator.pop(context, true); 
      } else {
        final responseBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $responseBody')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create New Post')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 50, color: Colors.grey),
                            Text('Tap to select image'),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 16),

              // Title input
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Body input
              TextFormField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: 'Body',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter post content';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Read Time input
              TextFormField(
                controller: _readTimeController,
                decoration: InputDecoration(
                  labelText: 'Read Time (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter read time';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Category selection
              Text('Select Categories', style: TextStyle(fontSize: 16)),
              Wrap(
                spacing: 8,
                children: categories.map((category) {
                  return FilterChip(
                    label: Text(category['title']),
                    selected: _selectedCategories.contains(category['id']),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category['id']);
                        } else {
                          _selectedCategories.remove(category['id']);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _submitPost,
                child: Text('Create Post'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}