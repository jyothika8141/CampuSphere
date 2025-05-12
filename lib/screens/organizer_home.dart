import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/event_service.dart';
import 'login_page.dart';

class OrganizerHome extends StatefulWidget {
  const OrganizerHome({Key? key}) : super(key: key);

  @override
  _OrganizerHomeState createState() => _OrganizerHomeState();
}

class _OrganizerHomeState extends State<OrganizerHome> {
  final EventService _eventService = EventService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _prefillDepartment();
  }

  Future<void> _prefillDepartment() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final userDoc = await _db.collection('users').doc(userId).get();
        if (userDoc.exists && userDoc['department'] != null) {
          setState(() {
            _departmentController.text = userDoc['department'].toString();
          });
        }
      }
    } catch (e) {
      print('Error prefilling department: $e');
    }
  }

  Future<void> _createEvent() async {
    print('Create event button pressed, selected date: $_selectedDate');
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      try {
        await _eventService.createEvent(
          _titleController.text.trim(),
          _descriptionController.text.trim(),
          _selectedDate!,
          _departmentController.text.trim(),
        );
        _titleController.clear();
        _descriptionController.clear();
        _departmentController.clear();
        _selectedDate = null;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Event Created'),
            backgroundColor: Colors.indigo[600],
          ),
        );
        Navigator.pop(context); // Close the drawer
        setState(() {}); // Refresh the list
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create event: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else if (_selectedDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an event date'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser!.uid;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Organizer - Manage Events'),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.indigo[100]),
            onPressed: () => _scaffoldKey.currentState!.openDrawer(),
            tooltip: 'Create Event',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.indigo[100]),
            onPressed: _signOut,
            tooltip: 'Logout',
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
            child: SingleChildScrollView(
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
                          'Organizer Menu',
                          style: TextStyle(
                            color: Colors.indigo[100],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Create New Event',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[50],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Event Title',
                              prefixIcon: Icon(Icons.event, color: Colors.indigo[600]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.indigo[600]!, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter an event title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Event Description',
                              prefixIcon: Icon(Icons.description, color: Colors.indigo[600]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.indigo[600]!, width: 2),
                              ),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _departmentController,
                            decoration: InputDecoration(
                              labelText: 'Department',
                              prefixIcon: Icon(Icons.school, color: Colors.indigo[600]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.indigo[600]!, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a department';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Builder(
                            builder: (BuildContext dateContext) {
                              return ElevatedButton(
                                onPressed: () async {
                                  print('Opening date picker');
                                  try {
                                    DateTime? picked = await showDatePicker(
                                      context: dateContext,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2101),
                                    );
                                    if (picked != null && mounted) {
                                      print('Date selected: $picked');
                                      setState(() {
                                        _selectedDate = picked;
                                      });
                                    } else {
                                      print('No date selected');
                                    }
                                  } catch (e) {
                                    print('Error opening date picker: $e');
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to open date picker: ${e.toString()}'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo[600],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(
                                  _selectedDate == null
                                      ? 'Select Event Date'
                                      : 'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              print('Create event button pressed, selected date: $_selectedDate');
                              _createEvent();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Create Event',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('events').where('organizerId', isEqualTo: userId).snapshots(),
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

          final events = snapshot.data!.docs;

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.indigo[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No events created yet.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.indigo[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create an event to get started!',
                    style: TextStyle(fontSize: 16, color: Colors.indigo[700]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final attendees = List<String>.from(event['attendees'] ?? []);
              // Format date
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
                        'Total Attendees: ${attendees.length}',
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
    );
  }
}