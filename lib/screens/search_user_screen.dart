import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class SearchUserScreen extends StatefulWidget {
  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _emailController = TextEditingController();
  final ChatService _chatService = ChatService();
  final String myId = FirebaseAuth.instance.currentUser!.uid;

  void _searchAndChat() async {
    var userDoc = await _chatService.searchUserByEmail(_emailController.text.trim());
    if (userDoc != null) {
      String friendId = userDoc.id;
      String chatId = await _chatService.createOrGetChatRoom(myId, friendId);

      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatScreen(chatId: chatId, receiverId: friendId),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not found')));
    }
  }

  Stream<QuerySnapshot> _getMyChats() {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: myId)
        .snapshots();
  }

  Future<String> _getFriendEmail(String friendId) async {
    var userDoc = await FirebaseFirestore.instance.collection('users').doc(friendId).get();
    if (userDoc.exists) {
      return userDoc['email'] ?? 'Unknown';
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Student')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Enter student email'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _searchAndChat,
              child: Text('Search and Chat'),
            ),
            SizedBox(height: 30),

            // Heading for Previous Chats
            Text(
              'Previous Chats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Previous Chats List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getMyChats(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var chats = snapshot.data!.docs;

                  if (chats.isEmpty) {
                    return Center(child: Text('No previous chats.'));
                  }

                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      var chat = chats[index];
                      List participants = chat['participants'];
                      String friendId = participants.firstWhere((id) => id != myId);
                      String chatId = chat.id;

                      return FutureBuilder<String>(
                        future: _getFriendEmail(friendId),
                        builder: (context, emailSnapshot) {
                          if (!emailSnapshot.hasData) {
                            return ListTile(title: Text('Loading...'));
                          }

                          return ListTile(
                            title: Text(emailSnapshot.data!),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ChatScreen(chatId: chatId, receiverId: friendId),
                              ));
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
