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
