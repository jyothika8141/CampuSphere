import 'package:cloud_firestore/cloud_firestore.dart';

class ForumService {
  Future<String> getEmailFromUserId(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      return userDoc['email'] ?? 'Unknown User';
    } catch (e) {
      return 'Error fetching email';
    }
  }
}