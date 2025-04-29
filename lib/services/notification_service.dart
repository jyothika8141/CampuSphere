import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static const String serverKey = 'YOUR_FCM_SERVER_KEY'; // Replace with your FCM server key

  static Future<void> sendNotification(String receiverId, String message) async {
    var receiverDoc = await FirebaseFirestore.instance.collection('users').doc(receiverId).get();
    if (!receiverDoc.exists) return;

    String? token = receiverDoc['fcmToken'];
    if (token == null) return;

    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode({
        'to': token,
        'notification': {
          'title': 'New Message',
          'body': message,
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      }),
    );
  }
}
