import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class EditEventScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  
  EditEventScreen({required this.event});

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final storage = FlutterSecureStorage();
  bool _isLoading = false;

  TextEditingController _nameController = TextEditingController();
  TextEditingController _shortDescController = TextEditingController();
  TextEditingController _descController = TextEditingController();
  TextEditingController _socialMediaController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  TextEditingController _timeStartController = TextEditingController();
  TextEditingController _timeEndController = TextEditingController();

  File? _selectedImage;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();
  DateTime? selectedDate;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Populate form fields with existing event data
    _nameController.text = widget.event['name'] ?? '';
    _shortDescController.text = widget.event['short_desc'] ?? '';
    _descController.text = widget.event['desc'] ?? '';
    _socialMediaController.text = widget.event['social_media'] ?? '';
    _existingImageUrl = widget.event['img_url'];

    // Parse and set date
    if (widget.event['date'] != null) {
      try {
        selectedDate = DateTime.parse(widget.event['date']);
        _dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate!);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    // Parse and set times
    if (widget.event['time_start'] != null) {
      try {
        final startTimeParts = widget.event['time_start'].split(':');
        selectedStartTime = TimeOfDay(
          hour: int.parse(startTimeParts[0]),
          minute: int.parse(startTimeParts[1])
        );
        _timeStartController.text = _formatTimeOfDay(selectedStartTime!);
      } catch (e) {
        print('Error parsing start time: $e');
      }
    }

    if (widget.event['time_end'] != null) {
      try {
        final endTimeParts = widget.event['time_end'].split(':');
        selectedEndTime = TimeOfDay(
          hour: int.parse(endTimeParts[0]),
          minute: int.parse(endTimeParts[1])
        );
        _timeEndController.text = _formatTimeOfDay(selectedEndTime!);
      } catch (e) {
        print('Error parsing end time: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2025),
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
      initialTime: isStartTime ? selectedStartTime ?? TimeOfDay.now() 
                              : selectedEndTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          selectedStartTime = picked;
          _timeStartController.text = _formatTimeOfDay(picked);
        } else {
          selectedEndTime = picked;
          _timeEndController.text = _formatTimeOfDay(picked);
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await storage.read(key: 'auth_token');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://secretly-immortal-ghoul.ngrok-free.app/api/events/${widget.event['id']}')
      );

      request.fields['_method'] = 'PUT';
      
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = _nameController.text;
      request.fields['short_desc'] = _shortDescController.text;
      request.fields['desc'] = _descController.text;
      request.fields['social_media'] = _socialMediaController.text;
      request.fields['date'] = DateFormat('yyyy-MM-dd').format(selectedDate!);
      
      request.fields['time_start'] = selectedStartTime!.hour.toString().padLeft(2, '0') + 
                                   ':' + 
                                   selectedStartTime!.minute.toString().padLeft(2, '0');
      
      request.fields['time_end'] = selectedEndTime!.hour.toString().padLeft(2, '0') + 
                                 ':' + 
                                 selectedEndTime!.minute.toString().padLeft(2, '0');

      if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'img',
          _selectedImage!.path
        ));
      }

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('Response: $responseBody');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Event updated successfully',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.blue[400],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: EdgeInsets.all(20),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Error updating event: $responseBody',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[400],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: EdgeInsets.all(20),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Error updating event: $e',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[400],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: EdgeInsets.all(20),
        ),
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
        Container(
          color: Colors.black.withOpacity(0.3),
        ),
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFFA594F9),
                ),
                SizedBox(height: 20),
                Text(
                  'Updating Event...',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
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
          appBar: AppBar(
            title: Text('Edit Event'),
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.black,
          ),
          backgroundColor: const Color(0xFFF6F6F6),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
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
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image, size: 50, color: Colors.grey[400]),
                                      SizedBox(height: 8),
                                      Text(
                                        'Tap to select image',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Form fields with consistent styling
                  _buildStyledTextField(
                    controller: _nameController,
                    label: 'Event Name',
                    hint: 'Enter event name',
                  ),
                  SizedBox(height: 16),

                  _buildStyledTextField(
                    controller: _shortDescController,
                    label: 'Short Description',
                    hint: 'Enter short description',
                  ),
                  SizedBox(height: 16),

                  _buildStyledTextField(
                    controller: _descController,
                    label: 'Full Description',
                    hint: 'Enter full description',
                    maxLines: 4,
                  ),
                  SizedBox(height: 16),

                  _buildStyledTextField(
                    controller: _socialMediaController,
                    label: 'Social Media',
                    hint: 'Enter social media link',
                  ),
                  SizedBox(height: 16),

                  // Date picker
                  _buildDatePicker(),
                  SizedBox(height: 16),

                  // Time pickers
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePicker(
                          controller: _timeStartController,
                          label: 'Start Time',
                          onTap: () => _selectTime(context, true),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildTimePicker(
                          controller: _timeEndController,
                          label: 'End Time',
                          onTap: () => _selectTime(context, false),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Update button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          spreadRadius: 3,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: _isLoading ? null : _updateEvent,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Update Event',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
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

  // Helper method for styled text fields
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

  // Helper method for date picker
  Widget _buildDatePicker() {
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
        controller: _dateController,
        enabled: !_isLoading,
        readOnly: true,
        onTap: () => _selectDate(context),
        decoration: InputDecoration(
          labelText: 'Date',
          suffixIcon: Icon(Icons.calendar_today),
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
            return 'Please select a date';
          }
          return null;
        },
      ),
    );
  }

  // Helper method for time picker
  Widget _buildTimePicker({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
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
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(Icons.access_time),
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
            return 'Please select a time';
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescController.dispose();
    _descController.dispose();
    _socialMediaController.dispose();
    _dateController.dispose();
    _timeStartController.dispose();
    _timeEndController.dispose();
    super.dispose();
  }
}