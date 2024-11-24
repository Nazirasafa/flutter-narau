import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final storage = FlutterSecureStorage();
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shortDescController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _socialMediaController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeStartController = TextEditingController();
  final TextEditingController _timeEndController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  DateTime? selectedDate;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          selectedStartTime = picked;
          _timeStartController.text = picked.format(context);
        } else {
          selectedEndTime = picked;
          _timeEndController.text = picked.format(context);
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await storage.read(key: 'auth_token');
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('https://secretly-immortal-ghoul.ngrok-free.app/api/events')
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      request.fields['name'] = _nameController.text;
      request.fields['short_desc'] = _shortDescController.text;
      request.fields['desc'] = _descController.text;
      request.fields['social_media'] = _socialMediaController.text;
      request.fields['date'] = _dateController.text;
      request.fields['time_start'] = _formatTimeOfDay(selectedStartTime!);
      request.fields['time_end'] = _formatTimeOfDay(selectedEndTime!);

      if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'img', 
          _selectedImage!.path
        ));
      }

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event created successfully')),
        );
        Navigator.pop(context, true);
      } else {
        final responseBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating event: $responseBody')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating event: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildLoadingOverlay() {
    return Stack(
      children: [
        // Semi-transparent background
        Container(
          color: Colors.black.withOpacity(0.5),
        ),
        // Loading indicator and text
        Center(
          child: Container(
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 28),
                Text(
                  'Creating Event...',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: Text('Create New Event')),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image picker
                  GestureDetector(
                    onTap: _isLoading ? null : _pickImage,
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
                                Text('Tap to select image (jpeg, png, jpg, gif, svg)'),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Name input
                  TextFormField(
                    controller: _nameController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Event Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter event name';
                      }
                      if (value.length > 255) {
                        return 'Name must be less than 255 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Short Description input
                  TextFormField(
                    controller: _shortDescController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Short Description',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter short description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Full Description input
                  TextFormField(
                    controller: _descController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Full Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter full description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Social Media input
                  TextFormField(
                    controller: _socialMediaController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Social Media',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter social media';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Date picker
                  TextFormField(
                    controller: _dateController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a date';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Time Start picker
                  TextFormField(
                    controller: _timeStartController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Start Time',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(context, true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select start time';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Time End picker
                  TextFormField(
                    controller: _timeEndController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'End Time',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(context, false),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select end time';
                      }
                      if (selectedStartTime != null && selectedEndTime != null) {
                        final startDateTime = DateTime(2024, 1, 1, selectedStartTime!.hour, selectedStartTime!.minute);
                        final endDateTime = DateTime(2024, 1, 1, selectedEndTime!.hour, selectedEndTime!.minute);
                        if (endDateTime.isBefore(startDateTime)) {
                          return 'End time must be after start time';
                        }
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitEvent,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Create Event'),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }
}