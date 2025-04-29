import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String organizerId;
  final List<String> attendees;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.organizerId,
    required this.attendees,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'],
      description: data['description'],
      date: (data['date'] as Timestamp).toDate(),
      organizerId: data['organizerId'],
      attendees: List<String>.from(data['attendees']),
    );
  }
}
