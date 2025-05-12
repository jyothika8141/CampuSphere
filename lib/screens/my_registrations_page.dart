import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyRegistrationsPage extends StatelessWidget {
  const MyRegistrationsPage({Key? key}) : super(key: key);

  // Function to fetch organizer email from users collection
  Future<String> _getOrganizerEmail(String organizerId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(organizerId)
          .get();
      return userDoc.exists ? userDoc['email']?.toString() ?? 'Unknown Organizer' : 'Unknown Organizer';
    } catch (e) {
      return 'Unknown Organizer';
    }
  }

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
                  // Format date if it exists
                  String formattedDate = 'No date available';
                  if (event['date'] != null) {
                    if (event['date'] is Timestamp) {
                      formattedDate = DateFormat('MMM dd, yyyy').format((event['date'] as Timestamp).toDate());
                    } else if (event['date'] is String) {
                      try {
                        formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(event['date']));
                      } catch (e) {
                        formattedDate = 'Invalid date';
                      }
                    }
                  }

                  // Fetch organizer email based on organizerId
                  return FutureBuilder<String>(
                    future: _getOrganizerEmail(event['organizerId'] ?? ''),
                    builder: (context, organizerSnapshot) {
                      String organizerEmail = 'Unknown Organizer';
                      if (organizerSnapshot.connectionState == ConnectionState.done &&
                          organizerSnapshot.hasData) {
                        organizerEmail = organizerSnapshot.data!;
                      }

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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event['description'] ?? 'No description available',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.indigo[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Organizer: $organizerEmail',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.indigo[700],
                                    fontWeight: FontWeight.bold, // Made bold
                                  ),
                                ),
                                Text(
                                  'Date: $formattedDate',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.indigo[700],
                                    fontWeight: FontWeight.bold, // Made bold
                                  ),
                                ),
                                Text(
                                  'Department: ${event['department'] ?? 'Not specified'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.indigo[700],
                                    fontWeight: FontWeight.bold, // Made bold
                                  ),
                                ),
                              ],
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
          );
        },
      ),
    );
  }
}