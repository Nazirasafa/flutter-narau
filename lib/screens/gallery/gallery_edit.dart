import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class EditGalleryScreen extends StatefulWidget {
  final Map<String, dynamic> gallery;

  EditGalleryScreen({required this.gallery});

  @override
  _EditGalleryScreenState createState() => _EditGalleryScreenState();
}

class _EditGalleryScreenState extends State<EditGalleryScreen> {
  final _formKey = GlobalKey<FormState>();
  final storage = FlutterSecureStorage();
  bool _isLoading = false;

  TextEditingController _nameController = TextEditingController();
  TextEditingController _descController = TextEditingController();

  File? _selectedImage;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Populate form fields with existing gallery data
    _nameController.text = widget.gallery['name'] ?? '';
    _descController.text = widget.gallery['desc'] ?? '';
    _existingImageUrl = widget.gallery['img'] ?? '';
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _updateGallery() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await storage.read(key: 'auth_token');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://secretly-immortal-ghoul.ngrok-free.app/api/galleries/${widget.gallery['id']}')
      );

      request.fields['_method'] = 'PUT';

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = _nameController.text;
      request.fields['desc'] = _descController.text;

      if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'img',
          _selectedImage!.path
        ));
      }

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery updated successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating gallery: $responseBody')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Gallery'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Container(
                  height: 200,
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : _existingImageUrl != null
                            ? Image.network(_existingImageUrl!, fit: BoxFit.cover)
                            : Center(
                                child: Text(
                                  'Tap to select image',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              _buildStyledTextField(
                controller: _nameController,
                label: 'Gallery Name',
                hint: 'Enter gallery name',
              ),
              SizedBox(height: 16),
              _buildStyledTextField(
                controller: _descController,
                label: 'Description',
                hint: 'Enter description',
                maxLines: 4,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateGallery,
                child: Text('Update Gallery'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: !_isLoading,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}