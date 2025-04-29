// screens/my_registrations_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRegistrationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text('My Registrations')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('registrations')
            .where('studentId', isEqualTo: userId)
            .snapshots(),
        builder: (context, registrationSnapshot) {
          if (!registrationSnapshot.hasData) return Center(child: CircularProgressIndicator());

          var registrations = registrationSnapshot.data!.docs;

          if (registrations.isEmpty) {
            return Center(child: Text('No registrations yet.'));
          }

          return ListView.builder(
            itemCount: registrations.length,
            itemBuilder: (context, index) {
              var reg = registrations[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('events').doc(reg['eventId']).get(),
                builder: (context, eventSnapshot) {
                  if (!eventSnapshot.hasData) return ListTile(title: Text('Loading event...'));

                  var event = eventSnapshot.data!;
                  return ListTile(
                    title: Text(event['title']),
                    subtitle: Text(event['description']),
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
