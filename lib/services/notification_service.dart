import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize push notifications
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');

      // Get device token
      String? token = await _fcm.getToken();
      print("📱 FCM Token: $token");
      await _saveDeviceToken(token);

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 Foreground message: ${message.notification?.title}');
        // You can show a dialog/snackbar here
      });

      // When app is opened from a notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📨 Opened app from notification: ${message.notification?.title}');
        // Navigate if needed
      });
    }
  }

  // Save device token to user document
  Future<void> _saveDeviceToken(String? token) async {
    if (token == null || _auth.currentUser == null) return;

    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Send a chat notification to receiver
  static Future<void> sendNotification(
      String receiverId,
      String title,
      String body,
      ) async {
    try {
      // Get receiver's FCM tokens
      final receiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();

      final tokens = List<String>.from(receiverDoc['fcmTokens'] ?? []);

      if (tokens.isEmpty) {
        print('No FCM tokens found for receiver');
        return;
      }

      // In a real app, you would send this via your backend server
      // or Firebase Cloud Functions for security
      print('📤 Sending notification to $receiverId');
      print('Title: $title');
      print('Body: $body');
      print('Tokens: $tokens');

      // Here you would typically make an HTTP request to your server
      // or call a Cloud Function to send the actual notification
      // This is just a placeholder for the actual implementation
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}