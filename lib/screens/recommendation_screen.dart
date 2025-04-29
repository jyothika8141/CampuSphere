import 'package:flutter/material.dart';
import '../services/ai_services.dart';

class RecommendationScreen extends StatefulWidget {
  final String department;
  final String bio;
  final List<Map<String, dynamic>> events;

  const RecommendationScreen({
    required this.department,
    required this.bio,
    required this.events,
    Key? key,
  }) : super(key: key);

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  Future<List<String>>? _recommendations;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    try {
      final recommendations = await getRecommendedEvents(
        department: widget.department,
        bio: widget.bio,
        events: widget.events,
      );

      setState(() => _recommendations = Future.value(recommendations));
    } catch (e) {
      print('Error fetching recommendations: $e');
      // Re-throw the error to be caught by FutureBuilder
      setState(() => _recommendations = Future.error(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecommendations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<String>>(
        future: _recommendations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load recommendations'),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadRecommendations,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final recommendations = snapshot.data ?? [];

          if (recommendations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No recommendations available'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadRecommendations,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadRecommendations,
            child: ListView.builder(
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(recommendations[index]),
                    leading: const Icon(Icons.star, color: Colors.amber),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}