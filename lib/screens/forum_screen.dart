import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/forum_service.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({Key? key}) : super(key: key);

  @override
  _ForumScreenState createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ForumService _forumService = ForumService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  Future<void> _createPost() async {
    final user = _auth.currentUser;
    if (user == null || _titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both title and message.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      await _db.collection('forum_posts').add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'authorId': user.uid,
        'timestamp': Timestamp.now(),
      });
      _titleController.clear();
      _messageController.clear();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post created successfully!'),
          backgroundColor: Colors.indigo[600],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create post: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          'Create New Post',
          style: TextStyle(color: Colors.indigo[900], fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title, color: Colors.indigo[600]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.indigo[600]!, width: 2),
                  ),
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Message',
                  prefixIcon: Icon(Icons.message, color: Colors.indigo[600]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.indigo[600]!, width: 2),
                  ),
                ),
                maxLines: 4,
                maxLength: 500,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.indigo[700]),
            ),
          ),
          ElevatedButton(
            onPressed: _createPost,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _openRepliesScreen(DocumentSnapshot post, String authorEmail) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RepliesScreen(
          postId: post.id,
          postTitle: post['title'],
          authorEmail: authorEmail,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        title: const Text('Student Forum'),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.indigo[100]),
            onPressed: _showCreatePostDialog,
            tooltip: 'Create new post',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('forum_posts').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading posts',
                style: TextStyle(color: Colors.indigo[900], fontSize: 16),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum, size: 64, color: Colors.indigo[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.indigo[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to post!',
                    style: TextStyle(fontSize: 16, color: Colors.indigo[700]),
                  ),
                ],
              ),
            );
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return FutureBuilder<String>(
                future: _forumService.getEmailFromUserId(post['authorId']),
                builder: (context, emailSnapshot) {
                  if (emailSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildPostLoading();
                  }

                  if (emailSnapshot.hasError || !emailSnapshot.hasData) {
                    return _buildPostCard(post, 'Unknown User');
                  }

                  return _buildPostCard(post, emailSnapshot.data!);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPostLoading() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 18,
              width: 150,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: double.infinity,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 12),
            Container(
              height: 12,
              width: 100,
              color: Colors.grey[200],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(DocumentSnapshot post, String authorEmail) {
    String formattedDate = 'Unknown date';
    if (post['timestamp'] != null && post['timestamp'] is Timestamp) {
      Timestamp timestamp = post['timestamp'] as Timestamp;
      DateTime dateTime = timestamp.toDate();
      formattedDate = DateFormat('MMM dd, yyyy, h:mm a').format(dateTime);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openRepliesScreen(post, authorEmail),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.indigo[100],
                    child: Icon(Icons.forum, color: Colors.indigo[600]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      post['title'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo[900],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post['message'],
                style: TextStyle(fontSize: 14, color: Colors.indigo[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.indigo[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      authorEmail,
                      style: TextStyle(fontSize: 12, color: Colors.indigo[600]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.access_time, size: 14, color: Colors.indigo[600]),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.indigo[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RepliesScreen extends StatefulWidget {
  final String postId;
  final String postTitle;
  final String authorEmail;

  const RepliesScreen({
    Key? key,
    required this.postId,
    required this.postTitle,
    required this.authorEmail,
  }) : super(key: key);

  @override
  _RepliesScreenState createState() => _RepliesScreenState();
}

class _RepliesScreenState extends State<RepliesScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ForumService _forumService = ForumService();
  final TextEditingController _replyController = TextEditingController();

  Future<void> _addReply() async {
    final user = _auth.currentUser;
    if (user == null || _replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reply.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      await _db
          .collection('forum_posts')
          .doc(widget.postId)
          .collection('replies')
          .add({
        'message': _replyController.text.trim(),
        'authorId': user.uid,
        'timestamp': Timestamp.now(),
      });
      _replyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reply posted successfully!'),
          backgroundColor: Colors.indigo[600],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post reply: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.postTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Posted by: ${widget.authorEmail}',
              style: TextStyle(fontSize: 12, color: Colors.indigo[100]),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('forum_posts')
                  .doc(widget.postId)
                  .collection('replies')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.indigo));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading replies',
                      style: TextStyle(color: Colors.indigo[900], fontSize: 16),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.comment, size: 64, color: Colors.indigo[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No replies yet.',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.indigo[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to reply!',
                          style: TextStyle(fontSize: 16, color: Colors.indigo[700]),
                        ),
                      ],
                    ),
                  );
                }

                final replies = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: replies.length,
                  itemBuilder: (context, index) {
                    final reply = replies[index];
                    return FutureBuilder<String>(
                      future: _forumService.getEmailFromUserId(reply['authorId']),
                      builder: (context, emailSnapshot) {
                        if (emailSnapshot.connectionState == ConnectionState.waiting) {
                          return _buildReplyLoading();
                        }

                        if (emailSnapshot.hasError || !emailSnapshot.hasData) {
                          return _buildReplyCard(reply, 'Unknown User');
                        }

                        return _buildReplyCard(reply, emailSnapshot.data!);
                      },
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      labelText: 'Write a reply...',
                      prefixIcon: Icon(Icons.comment, color: Colors.indigo[600]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.indigo[600]!, width: 2),
                      ),
                    ),
                    maxLines: 2,
                    maxLength: 200,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.indigo[600]),
                  onPressed: _addReply,
                  tooltip: 'Send reply',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyLoading() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 14,
              width: double.infinity,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 100,
              color: Colors.grey[200],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyCard(DocumentSnapshot reply, String authorEmail) {
    String formattedDate = 'Unknown date';
    if (reply['timestamp'] != null && reply['timestamp'] is Timestamp) {
      Timestamp timestamp = reply['timestamp'] as Timestamp;
      DateTime dateTime = timestamp.toDate();
      formattedDate = DateFormat('MMM dd, yyyy, h:mm a').format(dateTime);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reply['message'],
              style: TextStyle(fontSize: 14, color: Colors.indigo[800]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.indigo[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    authorEmail,
                    style: TextStyle(fontSize: 12, color: Colors.indigo[600]),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time, size: 14, color: Colors.indigo[600]),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12, color: Colors.indigo[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}