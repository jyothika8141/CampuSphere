import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationListenerWidget extends StatefulWidget {
  final String userId;
  final Widget child;

  const NotificationListenerWidget({
    required this.userId,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  State<NotificationListenerWidget> createState() => _NotificationListenerWidgetState();
}

class _NotificationListenerWidgetState extends State<NotificationListenerWidget> {
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: widget.userId)
        .where('read', isEqualTo: false) // Only show unread notifications
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _showNotification(change.doc);
        }
      }
    });
  }

  void _showNotification(DocumentSnapshot doc) async {
    // Mark as read immediately to prevent duplicate notifications
    await doc.reference.update({'read': true});

    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return;

    final title = data['title'] ?? 'Notification';
    final message = data['message'] ?? '';

    // Use a delay to ensure context is available
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}