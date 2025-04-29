// lib/screens/admin_home.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/event_service.dart';
import 'students_list_page.dart'; // for viewing all students

class AdminHome extends StatelessWidget {
  final EventService _eventService = EventService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - Manage All Events'),
        actions: [
          IconButton(
            icon: Icon(Icons.people_alt),
            tooltip: 'View Students',
            onPressed: () {
              // Navigate to Students List page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentsListPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventService.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No events available.'));
          }

          var events = snapshot.data!.docs;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              var event = events[index];
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(event['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event['description']),
                      SizedBox(height: 5),
                      Text('Date: ${event['date']}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _eventService.deleteEvent(event.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Event Deleted')),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
