import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EditPostScreen extends StatefulWidget {
  final int postId;

  const EditPostScreen({super.key, required this.postId});

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _readTimeController;

  XFile? _imageFile;
  List<dynamic> _categories = [];
  List<int> _selectedCategories = [];
  Map<String, dynamic>? _postData;
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    _readTimeController = TextEditingController();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Fetch user ID first
      _userId = int.tryParse(await storage.read(key: 'userid') ?? '');
      
      if (_userId == null) {
        _showErrorDialog('User authentication failed');
        return;
      }

      // Fetch post details and categories
      await Future.wait([
        _fetchPostDetails(),
        _fetchCategories()
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _showErrorDialog('Initialization error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _fetchPostDetails() async {
    final authToken = await storage.read(key: 'auth_token');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/posts/${widget.postId}'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _postData = json.decode(response.body)['data'];
          _titleController.text = _postData!['title'];
          _bodyController.text = _postData!['body'];
          _readTimeController.text = _postData!['read_time'].toString();
          _selectedCategories = List<int>.from(
            _postData!['categories'].map((cat) => cat['id'])
          );
        });
      } else {
        _showErrorDialog('Failed to load post details' + response.body);
      }
    } catch (e) {
      _showErrorDialog('Error fetching post details: $e');
    }
  }

  Future<void> _fetchCategories() async {
    final authToken = await storage.read(key: 'auth_token');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/categories'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _categories = json.decode(response.body)['data'];
        });
      } else {
        _showErrorDialog('Failed to load categories');
      }
    } catch (e) {
      _showErrorDialog('Error fetching categories: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile;
    });
  }

  Future<void> _updatePost() async {
    

    // Validate form and categories
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategories.isEmpty) {
      _showErrorDialog('Please select at least one category');
      return;
    }

    final authToken = await storage.read(key: 'auth_token');

    try {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('http://10.0.2.2:8000/api/posts/${widget.postId}')
      );

      request.headers['Authorization'] = 'Bearer $authToken';
      request.fields['_method'] = 'PUT'; // Laravel method spoofing
      request.fields['title'] = _titleController.text;
      request.fields['body'] = _bodyController.text;
      request.fields['read_time'] = _readTimeController.text;

      // Add category IDs
      for (int i = 0; i < _selectedCategories.length; i++) {
        request.fields['category_ids[$i]'] = _selectedCategories[i].toString();
      }

      // Add image if selected
      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'img', 
          _imageFile!.path
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        _showErrorDialog('Failed to update post: ${json.decode(responseBody)}');
      }
    } catch (e) {
      _showErrorDialog('Error updating post: $e');
      print(e);
    }
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
      appBar: AppBar(
        title: Text('Edit Post'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _updatePost,
          )
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Image Picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _imageFile != null
                        ? Image.file(File(_imageFile!.path), fit: BoxFit.cover)
                        : _postData?['img'] != null
                            ? Image.network(_postData!['img'], fit: BoxFit.cover)
                            : Center(child: Text('Tap to select image')),
                  ),
                ),
                SizedBox(height: 16),

                // Title Input
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
                    if (value.length > 255) {
                      return 'Title must be 255 characters or less';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Categories Multiselect
                Text('Categories', style: TextStyle(fontSize: 16)),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _categories.map((category) {
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
                SizedBox(height: 16),

                // Read Time Input
                TextFormField(
                  controller: _readTimeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Read Time (minutes)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter read time';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 0) {
                      return 'Please enter a valid read time';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Body Input
                TextFormField(
                  controller: _bodyController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Body',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter post body';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _readTimeController.dispose();
    super.dispose();
  }
}