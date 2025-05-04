import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({Key? key}) : super(key: key);

  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _emailController = TextEditingController();
  final ChatService _chatService = ChatService();
  final String myId = FirebaseAuth.instance.currentUser!.uid;

  void _searchAndChat() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an email.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      var userDoc = await _chatService.searchUserByEmail(email);
      if (userDoc != null) {
        String friendId = userDoc.id;
        String chatId = await _chatService.createOrGetChatRoom(myId, friendId);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(chatId: chatId, receiverId: friendId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not found'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        title: const Text('Search Student'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find a Student',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo[900],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Enter student email',
                        prefixIcon: Icon(Icons.email, color: Colors.indigo[600]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.indigo[600]!, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onSubmitted: (_) => _searchAndChat(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _searchAndChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[600],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Search and Chat',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Heading for Previous Chats
            Text(
              'Previous Chats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            const SizedBox(height: 12),

            // Previous Chats List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getMyChats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.indigo));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading chats',
                        style: TextStyle(color: Colors.indigo[900], fontSize: 16),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat, size: 64, color: Colors.indigo[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No previous chats.',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.indigo[900],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a new conversation!',
                            style: TextStyle(fontSize: 16, color: Colors.indigo[700]),
                          ),
                        ],
                      ),
                    );
                  }

                  var chats = snapshot.data!.docs;

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
                          if (emailSnapshot.connectionState == ConnectionState.waiting) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: const ListTile(
                                leading: CircleAvatar(child: CircularProgressIndicator()),
                                title: Text('Loading...'),
                              ),
                            );
                          }

                          if (emailSnapshot.hasError || !emailSnapshot.hasData) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo[100],
                                  child: Icon(Icons.person, color: Colors.indigo[600]),
                                ),
                                title: Text(
                                  'Unknown User',
                                  style: TextStyle(color: Colors.indigo[900]),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(chatId: chatId, receiverId: friendId),
                                    ),
                                  );
                                },
                              ),
                            );
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.indigo[100],
                                child: Icon(Icons.person, color: Colors.indigo[600]),
                              ),
                              title: Text(
                                emailSnapshot.data!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.indigo[900],
                                ),
                              ),
                              trailing: Icon(Icons.chat_bubble_outline, color: Colors.indigo[600]),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(chatId: chatId, receiverId: friendId),
                                  ),
                                );
                              },
                            ),
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