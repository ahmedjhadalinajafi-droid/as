import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Talks to the Hostinger PHP backend (push notifications, image hosting,
/// update check). If [baseUrl] is left as the placeholder, every method
/// no-ops gracefully so the app keeps working without a server.
class Backend {
  // ── EDIT THESE TWO AFTER UPLOADING server/ TO HOSTINGER ──────────────────
  // The folder (no trailing slash) that contains send_notification.php,
  // upload_image.php and version.json. Example:
  //   'https://yoursite.com'         (if you uploaded into public_html)
  //   'https://yoursite.com/app'     (if you uploaded into public_html/app)
  static const String baseUrl = 'https://ahlulbaytmosque.site/app/server';

  // Must match API_SECRET in server/config.php
  static const String secret = 'ahlulbayt-masjid-2026-Kx9mPq7Lz3Wn8Rv';
  // ─────────────────────────────────────────────────────────────────────────

  static bool get isConfigured => !baseUrl.contains('YOUR-DOMAIN');

  /// Tells the server to push "new question" to all admin devices.
  static Future<void> notifyNewQuestion(String preview) async {
    await _postNotification({'type': 'new_question', 'body': preview});
  }

  /// Tells the server to push "your question was answered" to one client.
  static Future<void> notifyAnswer(String clientToken, String preview) async {
    if (clientToken.isEmpty) return;
    await _postNotification(
        {'type': 'answer', 'token': clientToken, 'body': preview});
  }

  static Future<void> _postNotification(Map<String, String> body) async {
    if (!isConfigured) return;
    try {
      await http
          .post(
            Uri.parse('$baseUrl/send_notification.php'),
            headers: {
              'Content-Type': 'application/json',
              'X-API-Secret': secret,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      debugPrint('notify failed: $e');
    }
  }

  /// Uploads an image and returns its hosted URL, or null on any failure
  /// (caller should then fall back to base64-in-Firestore).
  static Future<String?> uploadImage(Uint8List bytes) async {
    if (!isConfigured) return null;
    try {
      final req = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/upload_image.php'))
        ..headers['X-API-Secret'] = secret
        ..files.add(http.MultipartFile.fromBytes('image', bytes,
            filename: 'img.jpg'));
      final streamed = await req.send().timeout(const Duration(seconds: 25));
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      if (data is Map && data['ok'] == true && data['url'] is String) {
        return data['url'] as String;
      }
    } catch (e) {
      debugPrint('upload failed: $e');
    }
    return null;
  }

  /// Checks version.json and shows an "update available" dialog if the server
  /// build number is higher than the installed one.
  static Future<void> checkForUpdate(BuildContext context) async {
    if (!isConfigured) return;
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/version.json'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final serverBuild = (data['build'] as num?)?.toInt() ?? 0;

      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;
      if (serverBuild <= currentBuild) return;

      final url = data['url'] as String? ?? '';
      final notes = data['notes'] as String? ?? '';
      final mandatory = data['mandatory'] == true;
      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: !mandatory,
        builder: (ctx) => AlertDialog(
          title: const Text('تحديث جديد متوفر 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الإصدار ${data['version'] ?? ''} متاح الآن.'),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(notes, style: const TextStyle(fontSize: 13)),
              ],
            ],
          ),
          actions: [
            if (!mandatory)
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('لاحقاً')),
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('تحديث الآن'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('update check failed: $e');
    }
  }
}
