import 'dart:convert';
import 'package:http/http.dart' as http;

/// Replace with your actual Gemini API key
const String geminiApiKey = '';
const String geminiEndpoint =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey';

Future<List<String>> getRecommendedEvents({
  required String department,
  required String interests,
  required List<Map<String, dynamic>> events,
}) async {
  final prompt = '''
You are an AI assistant helping recommend the best events for a student.
The student's department is "$department" and their interests are: "$interests".

Here is a list of upcoming events:
${events.map((e) => "- ${e['title']}: ${e['description']}").join('\n')}

Please return only a JSON list of titles you would recommend. Example: ["Event A", "Event B"]
''';

  final body = jsonEncode({
    "contents": [
      {
        "parts": [
          {"text": prompt}
        ]
      }
    ]
  });

  final response = await http.post(
    Uri.parse(geminiEndpoint),
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  print("Gemini API response:\n${response.body}"); // 👈 Logs full raw response

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates != null && candidates.isNotEmpty) {
      final content = candidates[0]['content']['parts'][0]['text'] ?? '';
      final match = RegExp(r'\[(.*?)\]', dotAll: true).firstMatch(content);
      if (match != null) {
        final titles = jsonDecode('[${match.group(1)}]') as List<dynamic>;
        return titles.map((e) => e.toString()).toList();
      }
    }
    throw Exception('Invalid AI response format.');
  } else {
    throw Exception('Gemini API error: ${response.statusCode} ${response.body}');
  }
}
