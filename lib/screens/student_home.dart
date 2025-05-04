import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';
import 'my_registrations_page.dart';
import 'forum_screen.dart';
import 'search_user_screen.dart';
import 'login_page.dart';
import 'recommendation_screen.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({Key? key}) : super(key: key);

  @override
  _StudentHomeState createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  final EventService _eventService = EventService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    NotificationService().initialize();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _navigateToRecommendations(BuildContext context) async {
    try {
      final snapshot = await _eventService.getEvents().first;
      final events = snapshot.docs.map((doc) {
        return {
          'title': doc['title']?.toString() ?? 'Untitled Event',
          'description': doc['description']?.toString() ?? 'No description',
        };
      }).toList();

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecommendationScreen(
            department: 'Computer Science',
            bio: 'Interested in AI and Machine Learning',
            events: events,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting recommendations: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

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
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Student',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.indigo[100],
              ),
            ),
            const Text(
              'Browse Events',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.indigo[100]),
            onPressed: () => _signOut(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo[700]!, Colors.indigo[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 160,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'CampuSphere',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Student Menu',
                          style: TextStyle(
                            color: Colors.indigo[100],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: Icon(Icons.recommend, color: Colors.indigo[100]),
                      title: Text(
                        'Recommendations',
                        style: TextStyle(color: Colors.indigo[50]),
                      ),
                      onTap: () => _navigateToRecommendations(context),
                    ),
                    ListTile(
                      leading: Icon(Icons.chat, color: Colors.indigo[100]),
                      title: Text(
                        'Chat',
                        style: TextStyle(color: Colors.indigo[50]),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SearchUserScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.forum, color: Colors.indigo[100]),
                      title: Text(
                        'Forum',
                        style: TextStyle(color: Colors.indigo[50]),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ForumScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.list_alt, color: Colors.indigo[100]),
                      title: Text(
                        'My Registrations',
                        style: TextStyle(color: Colors.indigo[50]),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MyRegistrationsPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventService.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.indigo,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading events.',
                style: TextStyle(
                  color: Colors.indigo[900],
                  fontSize: 16,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                    'No events available.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.indigo[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back soon!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.indigo[700],
                    ),
                  ),
                ],
              ),
            );
          }

          var events = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              var event = events[index];
              // Convert Timestamp to human-readable date
              String formattedDate = 'No date';
              if (event['date'] != null && event['date'] is Timestamp) {
                Timestamp timestamp = event['date'] as Timestamp;
                DateTime dateTime = timestamp.toDate();
                formattedDate = DateFormat('MMM dd, yyyy').format(dateTime);
              }

              // Get department
              String department = event['department']?.toString() ?? 'Not specified';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.indigo[100],
                            child: Icon(
                              Icons.event,
                              color: Colors.indigo[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              event['title']?.toString() ?? 'Untitled Event',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event['description']?.toString() ?? 'No description',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.indigo[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: $formattedDate',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.indigo[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<String>(
                        future: _getOrganizerEmail(event['organizerId']?.toString() ?? ''),
                        builder: (context, organizerSnapshot) {
                          String organizerEmail = organizerSnapshot.data ?? 'Loading...';
                          if (organizerSnapshot.hasError) {
                            organizerEmail = 'Unknown Organizer';
                          }
                          return Text(
                            'Organizer Email: $organizerEmail',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.indigo[600],
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Department: $department',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.indigo[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await _eventService.registerForEvent(event.id);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Successfully Registered!'),
                                  backgroundColor: Colors.indigo[600],
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Registration Failed: ${e.toString()}'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Register',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
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