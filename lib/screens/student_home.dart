import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';
import '../services/ai_services.dart';
import 'my_registrations_page.dart';
import 'forum_screen.dart';
import 'search_user_screen.dart';
import 'login_page.dart';
import 'recommendation_screen.dart';


class StudentHome extends StatefulWidget {
  @override
  _StudentHomeState createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  final EventService _eventService = EventService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    NotificationService().initialize();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  Future<void> _navigateToRecommendations(BuildContext context) async {
    try {
      final snapshot = await _eventService.getEvents().first;
      final events = snapshot.docs.map((doc) {
        return {
          'title': doc['title']?.toString() ?? 'Untitled Event',
          'description': doc['description']?.toString() ?? 'No description',
        };
      }).toList();

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecommendationScreen(
            department: 'Computer Science',
            bio: 'Interested in AI and Machine Learning',
            events: events,
            // apiKey: ', // Pass your API key here
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting recommendations: ${e.toString()}')),
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
            Text('Student'),
            Text(
              'Browse Events',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.recommend),
              title: Text('Recommendations'),
              onTap: () => _navigateToRecommendations(context),
            ),
            ListTile(
              leading: Icon(Icons.chat),
              title: Text('Chat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SearchUserScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.forum),
              title: Text('Forum'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ForumScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.list_alt),
              title: Text('My Registrations'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MyRegistrationsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventService.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No events available.'));
          }

          var events = snapshot.data!.docs;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              var event = events[index];
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(
                    event['title']?.toString() ?? 'Untitled Event',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event['description']?.toString() ?? 'No description'),
                      SizedBox(height: 5),
                      Text('Date: ${event['date']?.toString() ?? 'No date'}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    child: Text('Register'),
                    onPressed: () async {
                      await _eventService.registerForEvent(event.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Successfully Registered!')),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}




















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../services/event_service.dart';
// import '../services/notification_service.dart'; // Make sure this import exists
// import 'my_registrations_page.dart';
// import 'forum_screen.dart';
// import 'search_user_screen.dart';
// import 'login_page.dart';
//
// class StudentHome extends StatefulWidget {
//   @override
//   _StudentHomeState createState() => _StudentHomeState();
// }
//
// class _StudentHomeState extends State<StudentHome> {
//   final EventService _eventService = EventService();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   @override
//   @override
//   void initState() {
//     super.initState();
//     NotificationService().initialize();
//   }
//
//   Future<void> _signOut(BuildContext context) async {
//     try {
//       await _auth.signOut();
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => LoginPage()),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error signing out: ${e.toString()}')),
//       );
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Student'),
//             Text(
//               'Browse Events',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.logout),
//             onPressed: () => _signOut(context),
//             tooltip: 'Logout',
//           ),
//         ],
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: BoxDecoration(
//                 color: Theme.of(context).primaryColor,
//               ),
//               child: Text(
//                 'Menu',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                 ),
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.chat),
//               title: Text('Chat'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => SearchUserScreen()),
//                 );
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.forum),
//               title: Text('Forum'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => ForumScreen()),
//                 );
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.list_alt),
//               title: Text('My Registrations'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => MyRegistrationsPage()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _eventService.getEvents(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(child: Text('No events available.'));
//           }
//
//           var events = snapshot.data!.docs;
//
//           return ListView.builder(
//             itemCount: events.length,
//             itemBuilder: (context, index) {
//               var event = events[index];
//               return Card(
//                 margin: EdgeInsets.all(10),
//                 child: ListTile(
//                   title: Text(event['title'],
//                       style: TextStyle(fontWeight: FontWeight.bold)),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(event['description']),
//                       SizedBox(height: 5),
//                       Text('Date: ${event['date']}'),
//                     ],
//                   ),
//                   trailing: ElevatedButton(
//                     child: Text('Register'),
//                     onPressed: () async {
//                       await _eventService.registerForEvent(event.id);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Successfully Registered!')),
//                       );
//                     },
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }













// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../services/event_service.dart';
// import 'my_registrations_page.dart';
// import 'forum_screen.dart';
// import 'search_user_screen.dart'; // Add this import
//
// class StudentHome extends StatelessWidget {
//   final EventService _eventService = EventService();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Student - Events'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.chat), // Chat icon
//             tooltip: 'Chat',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => SearchUserScreen()),
//               );
//             },
//           ),
//           IconButton(
//             icon: Icon(Icons.forum),
//             tooltip: 'Forum',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ForumScreen()),
//               );
//             },
//           ),
//           IconButton(
//             icon: Icon(Icons.list_alt),
//             tooltip: 'My Registrations',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => MyRegistrationsPage()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _eventService.getEvents(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(child: Text('No events available.'));
//           }
//
//           var events = snapshot.data!.docs;
//
//           return ListView.builder(
//             itemCount: events.length,
//             itemBuilder: (context, index) {
//               var event = events[index];
//               return Card(
//                 margin: EdgeInsets.all(10),
//                 child: ListTile(
//                   title: Text(event['title'], style: TextStyle(fontWeight: FontWeight.bold)),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(event['description']),
//                       SizedBox(height: 5),
//                       Text('Date: ${event['date']}'),
//                     ],
//                   ),
//                   trailing: ElevatedButton(
//                     child: Text('Register'),
//                     onPressed: () async {
//                       await _eventService.registerForEvent(event.id);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Successfully Registered!')),
//                       );
//                     },
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }