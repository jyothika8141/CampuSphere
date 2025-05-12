import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizersListPage extends StatefulWidget {
  const OrganizersListPage({Key? key}) : super(key: key);

  @override
  _OrganizersListPageState createState() => _OrganizersListPageState();
}

class _OrganizersListPageState extends State<OrganizersListPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _deleteOrganizer(String userId, String userEmail) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Organizer'),
        content: Text('Are you sure you want to delete the organizer with email "$userEmail"?'),
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
            content: Text('Organizer "$userEmail" deleted'),
            backgroundColor: Colors.indigo[600],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete organizer: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
        title: const Text('Organizers List'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'All Organizers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('users').where('role', isEqualTo: 'organizer').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.indigo));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading organizers.',
                      style: TextStyle(color: Colors.indigo[900], fontSize: 16),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.supervisor_account, size: 64, color: Colors.indigo[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No organizers found.',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.indigo[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add organizers to manage events!',
                          style: TextStyle(fontSize: 16, color: Colors.indigo[700]),
                        ),
                      ],
                    ),
                  );
                }

                var organizers = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: organizers.length,
                  itemBuilder: (context, index) {
                    var organizer = organizers[index];
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
                              child: Icon(Icons.supervisor_account, color: Colors.indigo[600]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    organizer['email']?.toString() ?? 'No email',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.indigo[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Department: ${organizer['department']?.toString() ?? 'Not specified'}',
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
                              tooltip: 'Delete Organizer',
                              onPressed: () => _deleteOrganizer(
                                organizer.id,
                                organizer['email'] ?? 'Unknown',
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