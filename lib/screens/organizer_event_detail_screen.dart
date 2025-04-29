import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrganizerEventDetailsScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const OrganizerEventDetailsScreen({
    Key? key,
    required this.eventId,
    required this.eventTitle,
  }) : super(key: key);

  @override
  State<OrganizerEventDetailsScreen> createState() => _OrganizerEventDetailsScreenState();
}

class _OrganizerEventDetailsScreenState extends State<OrganizerEventDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event: ${widget.eventTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('events').doc(widget.eventId).snapshots(),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
            return const Center(child: Text('Event not found'));
          }

          final eventData = eventSnapshot.data!.data() as Map<String, dynamic>;
          final attendees = List<String>.from(eventData['attendees'] ?? []);

          if (attendees.isEmpty) {
            return const Center(
              child: Text(
                'No students registered yet',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: attendees.length,
            itemBuilder: (context, index) {
              final studentId = attendees[index];
              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(studentId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Loading...'),
                    );
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.error)),
                      title: Text('User ID: $studentId'),
                      subtitle: const Text('User data not found'),
                    );
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(userData['name']?.toString().substring(0, 1) ?? '?'),
                      ),
                      title: Text(userData['name'] ?? 'Unknown User'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userData['email'] ?? 'No email'),
                          if (userData['studentId'] != null)
                            Text('Student ID: ${userData['studentId']}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.email),
                        onPressed: () {
                          // Implement email functionality
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement export functionality
        },
        child: const Icon(Icons.import_export),
        tooltip: 'Export Attendees',
      ),
    );
  }
}