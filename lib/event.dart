import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class EventScreen extends StatefulWidget {
  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> filteredEvents = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    try {
      // Panggil API untuk mendapatkan data event
      final response =
          await http.get(Uri.parse('http://10.0.2.2:8000/api/events'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List;
        setState(() {
          events = data.map((item) => item as Map<String, dynamic>).toList();
          filteredEvents = events;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Failed to load events: $e');
    }
  }

  void searchEvents(String query) {
    setState(() {
      searchQuery = query;
      filteredEvents = events
          .where((event) =>
              event['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
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
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Events',
                        style: const TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Events in SMKN 4 Bogor',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                    ])),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFA594F9),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, index) =>
                          _buildEventCard(filteredEvents[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
      child: TextField(
        controller: _searchController,
        onChanged: searchEvents,
        decoration: InputDecoration(
          hintText: 'Search..',
          prefixIcon: Icon(
            Icons.search,
            size: 25,
            color: Colors.grey[500],
          ),
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildCategoryChip('Upcoming', true),
          const SizedBox(width: 8),
          _buildCategoryChip('Completed', false),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          color: isSelected ? const Color(0xFFA594F9) : Colors.grey[600],
        ),
      ),
      backgroundColor: isSelected ? const Color(0xFFF3F0FF) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display image at the top with full width and rounded corners
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: event['img'],
              height: 120,
              width: double.infinity,
              fit: BoxFit.contain,
              placeholder: (context, url) => Container(
                height: 120,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFA594F9),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 120,
                color: Colors.grey[200],
                child: const Icon(Icons.error),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title of the event
          Center(
            child: Text(
              event['name'],
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 4),

          // Short description of the event
          Center(
            child: Text(
              event['short_desc'],
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Poppins',
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),

          // Date and Time row
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('EEEE, d MMMM')
                    .format(DateTime.parse(event['date'])),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.access_time,
                color: Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${event['time_start']} - ${event['time_end']}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue[400],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(event: event),
                  ),
                );
              },
              child: const Text(
                'Detail',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventDetailScreen extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  // Helper function to launch URL
  void _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Function to add event to Google Calendar
  void _addToCalendar() async {
    final date = DateFormat('yyyyMMdd').format(DateTime.parse(event['date']));
    final timeStart = event['time_start'].toString().replaceAll(':', '');
    final timeEnd = event['time_end'].toString().replaceAll(':', '');
    final calendarUri = Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: '/calendar/render',
      queryParameters: {
        'action': 'TEMPLATE',
        'text': event['name'],
        'dates': '${date}T$timeStart/$date' 'T$timeEnd',
        'details': event['desc'],
      },
    );

    _launchURL(calendarUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 200.0,
              
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                  background: CachedNetworkImage(
                imageUrl: event['img'],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFA594F9),
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )),
            ),
          ];
        },
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Name
              Text(
                event['name'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              // Date and Time
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('d MMM')
                            .format(DateTime.parse(event['date'])),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE')
                            .format(DateTime.parse(event['date'])),
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event['time_start']} - ${event['time_end']}',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Social Media Icon
                  GestureDetector(
                    onTap: () => _launchURL(event['social_media']),
                    child:
                        const Icon(Icons.link, color: Colors.orange, size: 30),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Event Description with "Show More"
              Text(
                event['desc'],
                maxLines: 4, // Show limited lines initially
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              // Add to Calendar Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addToCalendar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Add to Calendar',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
