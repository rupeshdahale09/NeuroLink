// import 'dart:convert';

// import 'package:http/http.dart' as http;

// // ignore: constant_identifier_names
// const String OPENAI_API_KEY = 'YOUR_API_KEY_HERE';

// class AiService {
//   static const String _chatEndpoint = 'https://api.openai.com/v1/chat/completions';

//   Future<String> generateReply(String prompt) => sendMessageToAI(prompt);

//   Future<String> sendMessageToAI(String message) async {
//     final text = message.trim();
//     if (text.isEmpty) {
//       return 'Please say something and I will help you.';
//     }

//     if (OPENAI_API_KEY == 'YOUR_API_KEY_HERE') {
//       return _localFallback(text);
//     }

//     try {
//       final response = await http.post(
//         Uri.parse(_chatEndpoint),
//         headers: <String, String>{
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $OPENAI_API_KEY',
//         },
//         body: jsonEncode(<String, dynamic>{
//           'model': 'gpt-4o-mini',
//           'temperature': 0.4,
//           'messages': <Map<String, String>>[
//             <String, String>{
//               'role': 'system',
//               'content':
//                   'You are NeuroBot, a concise and supportive assistant for blind users. Keep responses clear and practical.',
//             },
//             <String, String>{'role': 'user', 'content': text},
//           ],
//         }),
//       );

//       if (response.statusCode == 200) {
//         final body = jsonDecode(response.body) as Map<String, dynamic>;
//         final choices = body['choices'] as List<dynamic>? ?? <dynamic>[];
//         if (choices.isNotEmpty) {
//           final messageMap = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
//           final content = (messageMap?['content'] ?? '').toString().trim();
//           if (content.isNotEmpty) {
//             return content;
//           }
//         }
//       }
//       return _localFallback(text);
//     } catch (_) {
//       return _localFallback(text);
//     }
//   }

//   String _localFallback(String prompt) {
//     final lower = prompt.toLowerCase();
//     if (lower.contains('time')) {
//       final now = DateTime.now();
//       return 'It is ${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}.';
//     }
//     if (lower.contains('help')) {
//       return 'You can say learn, play, communicate, control, or back. You can also say hello neurobot to start open conversation mode.';
//     }
//     if (lower.contains('lonely')) {
//       return 'You are not alone. I am here with you. Take a deep breath, and tell me what support you need right now.';
//     }
//     return 'I heard you say: $prompt. Add your OpenAI API key in ai_service.dart for smarter responses.';
//   }
// }
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const String _apiKey = "AIzaSyA7GLvX5dg4a9_3zh_FpddqNN_Pfwe4nl8";
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";

  Future<String> sendMessageToAI(String message) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl?key=$_apiKey"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "You are NeuroBot, a helpful assistant for blind users. Keep responses simple, clear, and supportive.\nUser: $message"
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (text != null && text.toString().isNotEmpty) {
          return text.toString();
        }
      }

      return _fallback(message);
    } catch (e) {
      return _fallback(message);
    }
  }

  String _fallback(String message) {
    final lower = message.toLowerCase();

    if (lower.contains("time")) {
      final now = DateTime.now();
      return "It is ${now.hour}:${now.minute}";
    }

    if (lower.contains("help")) {
      return "You can say learn, play, communicate, or navigate.";
    }

    return "I heard you. Can you please repeat or say help?";
  }
}