import 'dart:convert';
import 'package:http/http.dart' as http;

/// Replace with your actual Gemini API key (preferably from .env)
const String geminiApiKey = 'AIzaSyCypPs0WVkmn1CNhCHGTXeHp5Y-GpTfTmo';
const String geminiEndpoint =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey';

Future<List<String>> getRecommendedEvents({
  required String department,
  required String interests,
  required List<Map<String, dynamic>> events,
}) async {
  if (events.isEmpty) {
    print("No events provided for recommendation.");
    return [];
  }

  // Construct prompt for Gemini
  final prompt = '''
You are an AI assistant helping recommend the best events for a student.
The student's department is "$department" and their interests are: "$interests".

Here is a list of upcoming events:
${events.map((e) => "- ${e['title']}: ${e['description']}").join('\n')}

Return a JSON list of recommended event titles (e.g., ["Event A", "Event B"]). Do not include markdown, code blocks, or any other formatting. Only return the raw JSON array.
''';

  // Request body for Gemini
  final body = jsonEncode({
    "contents": [
      {
        "parts": [
          {"text": prompt}
        ]
      }
    ]
  });

  try {
    print("Prompt sent to Gemini:\n$prompt"); // Debug
    final response = await http.post(
      Uri.parse(geminiEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print("Gemini API response:\n${response.body}"); // Debug

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        String content = candidates[0]['content']['parts'][0]['text'] ?? '';

        // Remove markdown code blocks and extra whitespace
        content = content
            .replaceAll(RegExp(r'```json\n?|\n?```'), '')
            .trim();

        print("Cleaned content: $content"); // Debug

        try {
          // Attempt to parse the content as JSON
          final titles = jsonDecode(content) as List<dynamic>;

          // Clean up titles by taking only the part before the colon (if desired)
          return titles.map((e) {
            final title = e.toString();
            // Split on colon and take the first part, trimming whitespace
            return title.split(':').first.trim();
          }).toList();
        } catch (e) {
          print("Failed to parse JSON from content: $content");
          print("Parsing error: $e");
        }
      } else {
        print("No valid candidates in Gemini response.");
      }
    } else {
      print("Gemini API error: ${response.statusCode} ${response.body}");
      if (response.statusCode == 401) {
        print("Invalid API key. Please check your Gemini API key.");
      } else if (response.statusCode == 429) {
        print("Rate limit exceeded. Please try again later.");
      }
    }
  } catch (e) {
    print("Error calling Gemini API: $e");
  }

  return [];
}