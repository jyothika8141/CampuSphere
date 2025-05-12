import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createEvent(String title, String description, DateTime date, String department) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No organizer logged in');

    await _firestore.collection('events').add({
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date), // Standardized to Timestamp
      'department': department,
      'organizerId': user.uid,
      'attendees': [],
    });
  }

  Future<void> registerForEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Check if already registered
    final existing = await _firestore
        .collection('registrations')
        .where('eventId', isEqualTo: eventId)
        .where('studentId', isEqualTo: user.uid)
        .get();

    if (existing.docs.isEmpty) {
      await _firestore.collection('registrations').add({
        'eventId': eventId,
        'studentId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      throw Exception('Already registered for this event');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  Stream<QuerySnapshot> getEvents() {
    return _firestore.collection('events').snapshots();
  }

  Future<void> updateEvent(
      String eventId,
      String title,
      String description,
      DateTime date,
      String department,
      ) async {
    final userId = _auth.currentUser!.uid;
    await _firestore.collection('events').doc(eventId).update({
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'organizerId': userId,
      'department': department,
    });
  }
}