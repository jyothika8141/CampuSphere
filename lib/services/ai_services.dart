import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

Future<List<String>> getRecommendedEvents({
  required String department,
  required String bio,
  required List<Map<String, dynamic>> events,
  int maxRetries = 3,
}) async {
  const apiKey = ''; // Replace with your actual API key

  final prompt = '''
You are an AI assistant. Recommend events to a student based on their department and bio.

Student Department: $department
Student Bio: $bio

Available Events:
${events.map((e) => "- ${e['title']}: ${e['description']}").join('\n')}

Return only the event titles as bullet points.
''';

  final url = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
  );

  final headers = {
    'Content-Type': 'application/json',
  };

  final body = jsonEncode({
    "contents": [
      {
        "parts": [
          {"text": prompt}
        ]
      }
    ]
  });

  // Implement retry logic
  int attempts = 0;
  while (attempts < maxRetries) {
    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];

        // Fixed parsing of the response
        return content
            .split('\n')
            .map((line) => line.replaceAll(RegExp(r'^[-•\d.]+\s*'), '').trim())
            .where((line) => line.isNotEmpty)
            .toList();
      } else if (response.statusCode == 503) {
        // Service unavailable - retry after a delay
        attempts++;
        if (attempts >= maxRetries) {
          throw Exception('API service unavailable after $maxRetries attempts (status 503)');
        }
        // Exponential backoff: wait longer between each retry
        await Future.delayed(Duration(seconds: 1 << attempts)); // 2, 4, 8 seconds
        continue;
      } else {
        // Handle other error codes
        final errorBody = response.body;
        throw Exception('API request failed with status ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      attempts++;
      if (attempts >= maxRetries || !(e.toString().contains('503') || e.toString().contains('SocketException'))) {
        // Don't retry if it's not a network-related error or we've exceeded retry attempts
        throw Exception('Failed to get recommendations: $e');
      }
      await Future.delayed(Duration(seconds: 1 << attempts));
    }
  }

  // This point should not be reached due to the exception in the loop,
  // but Dart requires a return statement for all code paths
  throw Exception('Failed to get recommendations after $maxRetries attempts');
}