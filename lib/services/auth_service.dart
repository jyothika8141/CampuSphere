// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//next lineeee
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signUp(String email, String password, String role) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'email': email,
      'role': role,
    });

    return userCredential.user;
  }

  Future<User?> signIn(String email, String password) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  Future<String> getUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      return doc['role'];
    }
    throw Exception('User not logged in');
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

// services/event_service.dart

Future<void> registerForEvent(String eventId) async {
  var userId = FirebaseAuth.instance.currentUser!.uid;

  // Check if already registered (optional but better)
  var existingRegistration = await FirebaseFirestore.instance
      .collection('registrations')
      .where('eventId', isEqualTo: eventId)
      .where('studentId', isEqualTo: userId)
      .get();

  if (existingRegistration.docs.isEmpty) {
    // Not registered yet, so create registration
    await FirebaseFirestore.instance.collection('registrations').add({
      'eventId': eventId,
      'studentId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  } else {
    throw Exception('Already Registered');
  }
}


// next functionn
Future<void> saveUserData(User user) async {
  String? fcmToken = await FirebaseMessaging.instance.getToken();

  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'email': user.email,
    'role': 'student',  // or organizer/admin based on signup
    'fcmToken': fcmToken, // 🔥 Save FCM Token
  }, SetOptions(merge: true));
}

