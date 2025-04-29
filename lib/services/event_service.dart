// lib/services/event_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createEvent(String title, String description, DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No organizer logged in');

    await FirebaseFirestore.instance.collection('events').add({
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'department': 'cse', // or from input if needed
      'organizerId': user.uid,
      'attendees': [],
    });
  }


  // Future<void> registerForEvent(String eventId) async {
  //   await _firestore.collection('events').doc(eventId).update({
  //     'attendees': FieldValue.arrayUnion([_auth.currentUser!.uid]),
  //   });
  // }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  Stream<QuerySnapshot> getEvents() {
    return _firestore.collection('events').snapshots();
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register for an event
  Future<void> registerForEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Check if already registered
    final existing = await _db.collection('registrations')
        .where('eventId', isEqualTo: eventId)
        .where('studentId', isEqualTo: user.uid)
        .get();

    if (existing.docs.isEmpty) {
      await _db.collection('registrations').add({
        'eventId': eventId,
        'studentId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      throw Exception('Already Registered for this event');
    }
  }
}
