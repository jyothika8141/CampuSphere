// lib/screens/students_list_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentsListPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchStudents() async {
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    List<Map<String, dynamic>> students = [];
    for (var doc in snapshot.docs) {
      students.add({
        'email': doc['email'],
        'uid': doc.id,
      });
    }
    return students;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Students List')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchStudents(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var students = snapshot.data!;

          if (students.isEmpty) {
            return Center(child: Text('No Students Found.'));
          }

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              var student = students[index];
              return ListTile(
                title: Text(student['email']),
                subtitle: Text('UID: ${student['uid']}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // TODO: Add moderation/delete functionality here
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
