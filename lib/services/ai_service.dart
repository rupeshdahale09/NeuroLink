import 'dart:convert';

import 'package:http/http.dart' as http;

class AiService {
  Future<String> generateReply(String prompt) async {
    final lower = prompt.toLowerCase();

    if (lower.contains('lonely')) {
      return 'You are not alone. I am here with you. Would you like to hear a short calming activity or chat more?';
    }
    if (lower.contains('talk to me')) {
      return 'Of course. Tell me how your day has been so far.';
    }
    if (lower.contains('interesting')) {
      return await fetchInterestingFact();
    }
    if (lower.contains('time')) {
      final now = DateTime.now();
      return 'It is ${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}.';
    }
    if (lower.contains('weather')) {
      return 'The weather service is currently mocked. It is sunny and comfortable outside.';
    }

    return 'I heard you say: $prompt. How would you like me to assist next?';
  }

  Future<String> fetchInterestingFact() async {
    try {
      final res = await http.get(Uri.parse('https://api.quotable.io/random'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final content = (body['content'] ?? '').toString();
        if (content.isNotEmpty) {
          return 'Here is something interesting: $content';
        }
      }
    } catch (_) {}
    return 'Here is something interesting: The human brain can adapt throughout life, a process called neuroplasticity.';
  }
}
