import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:developer';
import 'dart:async';

class ReportService {
  // Update this to your new server endpoint that returns the PDF
  // The correct direct API URL for your Hugging Face Docker space
  static const String apiUrl = 'https://learnopolis-focusdesk-ai-server.hf.space/generate_report';

  Future<String?> fetchAndSaveReport({
    required Map<String, dynamic> context,
  }) async {
    try {
      log("-----------------------------------------");
      log("🚀 REQUESTING PDF REPORT");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(context),
      ).timeout(const Duration(seconds: 60));

      // ─── THE NEW ERROR CATCHER ───
      if (response.statusCode != 200) {
        log("🚨 SERVER REJECTED REQUEST!");
        log("🚨 Status Code: ${response.statusCode}");
        log("🚨 Server Reply: ${response.body}");
        return null;
      }

      // If it IS 200, save the PDF
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('application/json')) {
        log("⚠️ SERVER CRASHED AND SENT THIS ERROR: ${response.body}");
        return null;
      }

      log("📥 PDF RECEIVED. Saving to device...");
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime
          .now()
          .millisecondsSinceEpoch;
      final filePath = '${directory.path}/FocusDesk_Report_$timestamp.pdf';

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      log("✅ SAVED TO: $filePath");
      return filePath;
    } on TimeoutException catch (e) {
      log("⏰ TIMEOUT: $e");
      return null;
    } catch (e) {
      log("❌ UNKNOWN ERROR: $e");
      return null;
    }
  }
}