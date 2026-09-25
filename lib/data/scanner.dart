import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'species.dart';

/// One possible identification. [speciesId] is set when it's one of the
/// campus species; otherwise only [name] (and maybe [latin]) is known.
class ScanMatch {
  final String? speciesId;
  final String name;
  final String? latin;
  final bool? venomous;
  final int confidence;
  const ScanMatch({this.speciesId, required this.name, this.latin, this.venomous, required this.confidence});

  Species? get sp => speciesId == null ? null : speciesById(speciesId!);
}

class ScanResult {
  final bool isSnake;
  final List<ScanMatch> matches;
  final String? note;
  const ScanResult({required this.isSnake, required this.matches, this.note});
}

class ScanException implements Exception {
  final String message;
  const ScanException(this.message);
  @override
  String toString() => message;
}

/// Identifies snakes in photos with Claude. The Anthropic API key is typed in
/// by the user (Profile → Snake scanner key) and saved only on their device.
class Scanner {
  static const _prefsKey = 'anthropic_api_key';
  static const model = 'claude-sonnet-5';

  static Future<String?> loadKey() async {
    try {
      final k = (await SharedPreferences.getInstance()).getString(_prefsKey);
      return (k == null || k.trim().isEmpty) ? null : k.trim();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.trim().isEmpty) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, key.trim());
    }
  }

  static String _mediaType(Uint8List b) {
    if (b.length > 3 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return 'image/png';
    if (b.length > 3 && b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46) return 'image/gif';
    if (b.length > 11 && b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 && b[8] == 0x57 && b[9] == 0x45) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  static String get _prompt {
    final list = species.map((s) => '${s.id} | ${s.name} | ${s.latin} | ${s.venomous ? 'venomous' : 'non-venomous'}').join('\n');
    return '''
You identify snakes in photos for a snake-safety app on the IIT Guwahati campus in Assam, India.

These are the species recorded on or around campus (id | common name | scientific name | venom):
$list

Look at the photo and reply with ONLY a JSON object, no other text:
{
  "is_snake": true or false,
  "matches": [
    {"id": "<id from the list, or null if it is not one of them>", "name": "<common name>", "latin": "<scientific name>", "venomous": true, false or null if unknown, "confidence": <0-100>}
  ],
  "note": "<one short sentence on the features you used, or why you can't tell>"
}

Rules:
- Give up to 3 matches, most likely first. Confidences are percentages and together must not exceed 100.
- Prefer the campus species, but if the snake is clearly something else found in Northeast India, give it with "id": null.
- If the photo is unclear, keep confidences low and say so in the note.
- If there is no snake in the photo, set "is_snake" to false and "matches" to [].''';
  }

  static Future<ScanResult> identify(Uint8List image, String apiKey) async {
    final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'content-type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              // Lets the browser (web version) call the API directly.
              'anthropic-dangerous-direct-browser-access': 'true',
            },
            body: jsonEncode({
              'model': model,
              'max_tokens': 700,
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'image',
                      'source': {'type': 'base64', 'media_type': _mediaType(image), 'data': base64Encode(image)},
                    },
                    {'type': 'text', 'text': _prompt},
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw const ScanException('Couldn’t reach the scanner. Check your internet connection.');
    }

    if (res.statusCode == 401) throw const ScanException('The scanner key isn’t valid. Check it in Profile → Snake scanner key.');
    if (res.statusCode == 429) throw const ScanException('Too many scans right now. Wait a minute and try again.');
    if (res.statusCode >= 400) {
      String msg = 'Scanner error (${res.statusCode}).';
      try {
        msg = (jsonDecode(res.body)['error']['message'] as String?) ?? msg;
      } catch (_) {}
      throw ScanException(msg);
    }

    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final text = (body['content'] as List).where((c) => c['type'] == 'text').map((c) => c['text'] as String).join();
      final json = jsonDecode(text.substring(text.indexOf('{'), text.lastIndexOf('}') + 1)) as Map<String, dynamic>;
      final ids = species.map((s) => s.id).toSet();
      final matches = <ScanMatch>[
        for (final m in (json['matches'] as List? ?? const []).cast<Map<String, dynamic>>())
          ScanMatch(
            speciesId: ids.contains(m['id']) ? m['id'] as String : null,
            name: ids.contains(m['id']) ? speciesById(m['id'] as String).name : (m['name'] as String? ?? 'Unknown snake'),
            latin: ids.contains(m['id']) ? speciesById(m['id'] as String).latin : m['latin'] as String?,
            venomous: ids.contains(m['id']) ? speciesById(m['id'] as String).venomous : m['venomous'] as bool?,
            confidence: ((m['confidence'] as num?) ?? 0).round().clamp(0, 100),
          ),
      ];
      return ScanResult(isSnake: json['is_snake'] != false && matches.isNotEmpty, matches: matches.take(3).toList(), note: json['note'] as String?);
    } catch (_) {
      throw const ScanException('The scanner gave an answer the app couldn’t read. Try again.');
    }
  }
}
