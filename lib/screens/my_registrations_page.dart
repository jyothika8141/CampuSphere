import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRegistrationsPage extends StatelessWidget {
  const MyRegistrationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        title: const Text('My Registrations'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('registrations')
            .where('studentId', isEqualTo: userId)
            .snapshots(),
        builder: (context, registrationSnapshot) {
          if (registrationSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.indigo,
              ),
            );
          }

          if (registrationSnapshot.hasError) {
            return Center(
              child: Text(
                'Error loading registrations.',
                style: TextStyle(
                  color: Colors.indigo[900],
                  fontSize: 16,
                ),
              ),
            );
          }

          var registrations = registrationSnapshot.data!.docs;

          if (registrations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.indigo[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No registrations yet.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.indigo[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore events to join!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.indigo[700],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: registrations.length,
            itemBuilder: (context, index) {
              var reg = registrations[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('events').doc(reg['eventId']).get(),
                builder: (context, eventSnapshot) {
                  if (eventSnapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text('Loading event...'),
                        contentPadding: EdgeInsets.all(16.0),
                      ),
                    );
                  }

                  if (eventSnapshot.hasError || !eventSnapshot.hasData) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(
                          'Error loading event',
                          style: TextStyle(color: Colors.indigo[900]),
                        ),
                        contentPadding: const EdgeInsets.all(16.0),
                      ),
                    );
                  }

                  var event = eventSnapshot.data!;
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo[100],
                        child: Icon(
                          Icons.event,
                          color: Colors.indigo[600],
                        ),
                      ),
                      title: Text(
                        event['title'] ?? 'Untitled Event',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo[900],
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          event['description'] ?? 'No description available',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.indigo[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onTap: () {
                        // Optional: Add navigation to event details if needed
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}