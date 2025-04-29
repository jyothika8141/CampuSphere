import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverId;

  ChatScreen({required this.chatId, required this.receiverId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final String myId = FirebaseAuth.instance.currentUser!.uid;

  String receiverEmail = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadReceiverEmail();
  }

  void _loadReceiverEmail() async {
    var userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.receiverId).get();
    if (userDoc.exists) {
      setState(() {
        receiverEmail = userDoc['email'] ?? 'Unknown';
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    await _chatService.sendMessage(
      widget.chatId,
      myId,
      widget.receiverId,
      _messageController.text.trim(),
    );
    await NotificationService.sendNotification(widget.receiverId, _messageController.text.trim());
    _messageController.clear(); // <- Already correctly placed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(receiverEmail)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                var messages = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isMe = message['senderId'] == myId;
                    return Container(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(message['message']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(hintText: 'Type a message'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: _sendMessage,
              )
            ],
          ),
        ],
      ),
    );
  }
}
