import 'dart:convert';
import 'dart:io';

import 'hadith_book_remote_data_source.dart' show HttpGet;

/// Production [HttpGet]: a plain GET that returns the decoded body, using the
/// SDK's [HttpClient] so the app pulls in no extra networking dependency.
/// Throws on a non-200 response or timeout — the repository maps that to a
/// failure and the screen offers a retry.
Future<String> httpGetString(Uri url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.getUrl(url);
    final response = await request.close().timeout(const Duration(seconds: 20));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: url);
    }
    return await response.transform(utf8.decoder).join();
  } finally {
    client.close(force: true);
  }
}
