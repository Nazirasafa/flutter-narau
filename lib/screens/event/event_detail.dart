import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Event Image (Smaller)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  imageUrl: event['img'],
                  width: 240, // Smaller size for the image
                  //height: 120,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(
                    color: Color(0xFFA594F9),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              const SizedBox(height: 20),
              // Event Name
              Text(
                event['name'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              // Date and Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('d MMM').format(DateTime.parse(event['date'])),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE').format(DateTime.parse(event['date'])),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${event['time_start']} - ${event['time_end']}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Event Description
              Text(
                event['desc'],
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center align horizontally
                children: [
                  Expanded(
                    child: SizedBox(
                      width: double.maxFinite,
                      child: ElevatedButton(
                        onPressed: _addToCalendar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Add to Calendar',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                      width: 12), // Space between the button and icon
                  GestureDetector(
                    onTap: () => _launchURL(Uri.parse(event['social_media'])),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child:
                          const Icon(Icons.link, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.maxFinite,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white60,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(fontSize: 18, color: Colors.black38),  
                  ),
                ),
              ),

              // Add to Calendar Button
            ],
          ),
        ),
      ),
    );
  }
}
