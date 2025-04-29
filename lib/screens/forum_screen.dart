import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/forum_service.dart';

class ForumScreen extends StatefulWidget {
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
    if (user == null) return;

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post: ${e.toString()}')),
      );
    }
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Post'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _createPost,
            child: Text('Post'),
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
      appBar: AppBar(
        title: Text('Student Forum'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showCreatePostDialog,
            tooltip: 'Create new post',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('forum_posts').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading posts'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No posts yet. Be the first to post!'));
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(8),
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
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Container(
          height: 16,
          width: 100,
          color: Colors.grey[300],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 14,
              width: double.infinity,
              color: Colors.grey[200],
              margin: EdgeInsets.only(top: 8),
            ),
            Container(
              height: 12,
              width: 150,
              color: Colors.grey[200],
              margin: EdgeInsets.only(top: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(DocumentSnapshot post, String authorEmail) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _openRepliesScreen(post, authorEmail),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post['title'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(post['message']),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    authorEmail,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.comment, size: 14, color: Colors.grey),
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
    required this.postId,
    required this.postTitle,
    required this.authorEmail,
  });

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
    if (user == null || _replyController.text.trim().isEmpty) return;

    try {
      await _db.collection('forum_posts')
          .doc(widget.postId)
          .collection('replies')
          .add({
        'message': _replyController.text.trim(),
        'authorId': user.uid,
        'timestamp': Timestamp.now(),
      });
      _replyController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post reply: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.postTitle),
            Text(
              'Posted by: ${widget.authorEmail}',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('forum_posts')
                  .doc(widget.postId)
                  .collection('replies')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading replies'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No replies yet'));
                }

                final replies = snapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.all(8),
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
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      labelText: 'Write a reply...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                  onPressed: _addReply,
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
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Container(
          height: 14,
          width: double.infinity,
          color: Colors.grey[200],
        ),
        subtitle: Container(
          height: 12,
          width: 100,
          color: Colors.grey[100],
          margin: EdgeInsets.only(top: 8),
        ),
      ),
    );
  }

  Widget _buildReplyCard(DocumentSnapshot reply, String authorEmail) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reply['message'],
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  authorEmail,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}