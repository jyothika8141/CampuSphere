import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ai_services.dart';
import '../services/event_service.dart'; // Added import for EventService

class RecommendationScreen extends StatefulWidget {
  final String department;
  final String interests;

  const RecommendationScreen({
    super.key,
    required this.department,
    required this.interests,
  });

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  List<Map<String, dynamic>> _recommendedEvents = [];
  bool _isLoading = true;
  String? _errorMessage;
  final EventService _eventService = EventService(); // Initialize EventService

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch events from Firestore
      final eventsSnapshot = await FirebaseFirestore.instance.collection('events').get();
      final events = eventsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Get recommended event titles
      final recommendedTitles = await getRecommendedEvents(
        department: widget.department,
        interests: widget.interests,
        events: events,
      );

      // Filter events by recommended titles
      final recommendedEvents = events
          .where((event) => recommendedTitles.contains(event['title']))
          .toList();

      setState(() {
        _recommendedEvents = recommendedEvents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load recommendations: $e';
        _isLoading = false;
      });
      print('Error loading recommendations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Events'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.indigo[50],
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await _loadRecommendations();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        )
            : _recommendedEvents.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No recommended events found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await _loadRecommendations();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        )
            : ListView.builder(
          itemCount: _recommendedEvents.length,
          itemBuilder: (context, index) {
            final event = _recommendedEvents[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  event['title'] ?? 'No Title',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(event['description'] ?? 'No Description'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    try {
                      await _eventService.registerForEvent(event['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Successfully registered for ${event['title']}'),
                          backgroundColor: Colors.blueAccent,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Registration failed: $e'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Register'),
                ),
                onTap: () {
                  // Implement event details navigation
                },
              ),
            );
          },
        ),
      ),
    );
  }
}