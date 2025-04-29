import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DocumentSnapshot?> searchUserByEmail(String email) async {
    var users = await _db.collection('users').where('email', isEqualTo: email).get();
    if (users.docs.isNotEmpty) return users.docs.first;
    return null;
  }

  Future<String> createOrGetChatRoom(String myId, String friendId) async {
    var chatQuery = await _db
        .collection('chats')
        .where('participants', arrayContains: myId)
        .get();

    for (var doc in chatQuery.docs) {
      List participants = doc['participants'];
      if (participants.contains(friendId)) {
        return doc.id; // Chat room already exists
      }
    }

    var chatDoc = await _db.collection('chats').add({
      'participants': [myId, friendId],
      'timestamp': FieldValue.serverTimestamp(),
      'lastMessage': '',
    });

    return chatDoc.id;
  }

  Future<void> sendMessage(String chatId, String senderId, String receiverId, String message) async {
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _db.collection('chats').doc(chatId).update({
      'lastMessage': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db.collection('chats').doc(chatId).collection('messages').orderBy('timestamp').snapshots();
  }
}
