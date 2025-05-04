import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverId;

  const ChatScreen({required this.chatId, required this.receiverId, Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final ScrollController _scrollController = ScrollController();

  String _receiverEmail = 'Loading...';
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadReceiverInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _loadReceiverInfo() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverId)
          .get();

      if (mounted) {
        setState(() {
          _receiverEmail = userDoc['email'] ?? 'Unknown user';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _receiverEmail = 'Error loading user';
          _isLoading = false;
        });
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final messageText = _messageController.text.trim();

    try {
      await _chatService.sendMessage(
        widget.chatId,
        _currentUserId,
        widget.receiverId,
        messageText,
      );

      await NotificationService.sendNotification(
        widget.receiverId,
        'New message from ${_receiverEmail.split('@').first}',
        messageText,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        title: Text(
          _isLoading ? 'Loading...' : _receiverEmail,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.indigo));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages',
                      style: TextStyle(color: Colors.indigo[900], fontSize: 16),
                    ),
                  );
                }

                final messages = snapshot.data?.docs ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.indigo[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet.',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.indigo[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(fontSize: 16, color: Colors.indigo[700]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == _currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.indigo[600] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16).copyWith(
                            topLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                            topRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                            bottomLeft: const Radius.circular(16),
                            bottomRight: const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // if (!isMe)
                            //   Text(
                            //     _receiverEmail.split('@').first,
                            //     style: TextStyle(
                            //       fontSize: 12,
                            //       fontWeight: FontWeight.w600,
                            //       color: Colors.indigo[800],
                            //     ),
                            //   ),
                            const SizedBox(height: 4),
                            Text(
                              message['message'],
                              style: TextStyle(
                                fontSize: 14,
                                color: isMe ? Colors.white : Colors.indigo[900],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatTimestamp(message['timestamp']),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? Colors.indigo[100] : Colors.indigo[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      prefixIcon: Icon(Icons.message, color: Colors.indigo[600]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.indigo[600]!, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    minLines: 1,
                    maxLines: 3,
                    maxLength: 500,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSending
                      ? CircularProgressIndicator(color: Colors.indigo[600])
                      : Icon(Icons.send, color: Colors.indigo[600]),
                  onPressed: _sendMessage,
                  tooltip: 'Send message',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    final dateTime = timestamp.toDate();
    return DateFormat('MMM dd, yyyy, h:mm a').format(dateTime);
  }
}