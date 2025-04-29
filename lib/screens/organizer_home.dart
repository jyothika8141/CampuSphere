import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/event_service.dart';

class OrganizerHome extends StatefulWidget {
  @override
  _OrganizerHomeState createState() => _OrganizerHomeState();
}

class _OrganizerHomeState extends State<OrganizerHome> {
  final EventService _eventService = EventService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;

  void _createEvent() async {
    if (_selectedDate != null) {
      await _eventService.createEvent(
        _titleController.text,
        _descriptionController.text,
        _selectedDate!,
      );
      _titleController.clear();
      _descriptionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event Created')));
      setState(() {}); // Refresh the list after creation
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text('Organizer - Manage Events')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Create Event Section
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Event Title'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Event Description'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Text('Select Event Date'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _createEvent,
                child: Text('Create Event'),
              ),
              Divider(height: 40, thickness: 2),

              // Display My Events Section
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('events').where('organizerId', isEqualTo: userId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                  final events = snapshot.data!.docs;

                  if (events.isEmpty) {
                    return Center(child: Text('No events created yet.'));
                  }

                  return ListView.builder(
                    physics: NeverScrollableScrollPhysics(), // important
                    shrinkWrap: true,
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final attendees = List<String>.from(event['attendees'] ?? []);

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(event['title']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Description: ${event['description']}'),
                              SizedBox(height: 5),
                              Text('Date: ${event['date']}'),
                              SizedBox(height: 5),
                              Text('Total Attendees: ${attendees.length}'),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
