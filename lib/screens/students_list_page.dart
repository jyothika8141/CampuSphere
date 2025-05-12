import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_home.dart';
import 'organizers_list_page.dart';
import 'login_page.dart';

class StudentsListPage extends StatefulWidget {
  const StudentsListPage({Key? key}) : super(key: key);

  @override
  _StudentsListPageState createState() => _StudentsListPageState();
}

class _StudentsListPageState extends State<StudentsListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
        await _firestore.collection('users').doc(userId).delete();
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
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Students List'),
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
                  leading: Icon(Icons.event, color: Colors.indigo[100]),
                  title: Text(
                    'Manage Events',
                    style: TextStyle(color: Colors.indigo[50]),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminHome()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.people_alt, color: Colors.indigo[100]),
                  title: Text(
                    'View Students',
                    style: TextStyle(color: Colors.indigo[50]),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Already on StudentsListPage, no navigation needed
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
              'All Students',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').where('role', isEqualTo: 'student').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.indigo));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading students.',
                      style: TextStyle(color: Colors.indigo[900], fontSize: 16),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, size: 64, color: Colors.indigo[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No students found.',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.indigo[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add students to join events!',
                          style: TextStyle(fontSize: 16, color: Colors.indigo[700]),
                        ),
                      ],
                    ),
                  );
                }

                var students = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    var student = students[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.indigo[100],
                              child: Icon(Icons.person, color: Colors.indigo[600]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student['email']?.toString() ?? 'No email',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.indigo[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Department: ${student['department']?.toString() ?? 'Not specified'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.indigo[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.redAccent),
                              tooltip: 'Delete Student',
                              onPressed: () => _deleteUser(
                                student.id,
                                student['email'] ?? 'Unknown',
                                'Student',
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