import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/event_service.dart';
import 'students_list_page.dart';
import 'organizers_list_page.dart';
import 'login_page.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final EventService _eventService = EventService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) =>  LoginPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _deleteEvent(String eventId, String eventTitle) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "$eventTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _eventService.deleteEvent(eventId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event "$eventTitle" deleted'),
            backgroundColor: Colors.indigo[600],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete event: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId, String userEmail, String userType) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $userType'),
        content: Text('Are you sure you want to delete the $userType with email "$userEmail"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.collection('users').doc(userId).delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userType "$userEmail" deleted'),
            backgroundColor: Colors.indigo[600],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete $userType: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Admin - Manage Events'),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.indigo[100]),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
          tooltip: 'Menu',
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.indigo[100]),
            tooltip: 'Logout',
            onPressed: _signOut,
          ),
        ],
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo[700]!, Colors.indigo[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CampuSphere',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.indigo[100]),
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                      Text(
                        'Admin Menu',
                        style: TextStyle(
                          color: Colors.indigo[100],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.people_alt, color: Colors.indigo[100]),
                  title: Text(
                    'View Students',
                    style: TextStyle(color: Colors.indigo[50]),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentsListPage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.supervisor_account, color: Colors.indigo[100]),
                  title: Text(
                    'View Organizers',
                    style: TextStyle(color: Colors.indigo[50]),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrganizersListPage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.indigo[100]),
                  title: Text(
                    'Logout',
                    style: TextStyle(color: Colors.indigo[50]),
                  ),
                  onTap: _signOut,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'All Events',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _eventService.getEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.indigo));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading events.',
                      style: TextStyle(color: Colors.indigo[900], fontSize: 16),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.indigo[300]),
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
                          'Organizers will create events soon!',
                          style: TextStyle(fontSize: 16, color: Colors.indigo[700]),
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
                    String formattedDate = 'No date';
                    if (event['date'] != null && event['date'] is Timestamp) {
                      Timestamp timestamp = event['date'] as Timestamp;
                      DateTime dateTime = timestamp.toDate();
                      formattedDate = DateFormat('MMM dd, yyyy').format(dateTime);
                    }

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.indigo[100],
                                  child: Icon(Icons.event, color: Colors.indigo[600]),
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
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.redAccent),
                                  tooltip: 'Delete Event',
                                  onPressed: () => _deleteEvent(event.id, event['title'] ?? 'Untitled'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event['description']?.toString() ?? 'No description',
                              style: TextStyle(fontSize: 14, color: Colors.indigo[700]),
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
                            Text(
                              'Department: ${event['department']?.toString() ?? 'Not specified'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.indigo[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Attendees: ${List<String>.from(event['attendees'] ?? []).length}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.indigo[600],
                                fontWeight: FontWeight.w500,
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
          ),
        ],
      ),
    );
  }
}