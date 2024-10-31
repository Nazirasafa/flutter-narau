import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AgendaScreen extends StatefulWidget {
  @override
  _AgendaScreenState createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  List<dynamic> agendaList = [];
  bool isLoading = true;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchAgenda();
  }

  Future<void> fetchAgenda() async {
    final response = await http.get(Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0062311270/agenda.php'));

    if (response.statusCode == 200) {
      setState(() {
        agendaList = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load agenda');
    }
  }

  List<dynamic> getFilteredAgenda() {
    if (selectedDate == null) return agendaList;
    return agendaList.where((agenda) {
      DateTime agendaDate = DateTime.parse(agenda['tgl_agenda']);
      return agendaDate.year == selectedDate!.year &&
             agendaDate.month == selectedDate!.month &&
             agendaDate.day == selectedDate!.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda',
        style: TextStyle(
            fontWeight: FontWeight.w900, // Extra bold text
            fontSize: 18, // Smaller font size
          ),),
        
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2025),
              );
              if (picked != null && picked != selectedDate) {
                setState(() {
                  selectedDate = picked;
                });
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (selectedDate != null)
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Filtered Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: getFilteredAgenda().length,
                    itemBuilder: (context, index) {
                      final agenda = getFilteredAgenda()[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        elevation: 3, // Add some shadow for better separation
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0), // Add padding to the Card
                          child: ListTile(
                            title: Text(
                              agenda['judul_agenda'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8),
                                Text(
                                  'Date: ${agenda['tgl_agenda']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  agenda['isi_agenda'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AgendaDetailScreen(agenda: agenda),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class AgendaDetailScreen extends StatelessWidget {
  final Map<String, dynamic> agenda;

  const AgendaDetailScreen({Key? key, required this.agenda}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
        title: Text(
          agenda['judul_agenda'],
          style: TextStyle(
            fontWeight: FontWeight.w900, // Extra bold text
            fontSize: 18, // Smaller font size
            color: Color(0xFFA594F9),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              agenda['judul_agenda'],
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 8),
            Text(
              'Date: ${agenda['tgl_agenda']}',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Text(
              'Posted on: ${agenda['tgl_post_agenda']}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Text(
              agenda['isi_agenda'],
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
