import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../config/content_sources.dart';
import 'hadith_book_remote_data_source.dart' show HttpGet;

/// Production [HttpGet]: a plain GET that returns the decoded body, using the
/// SDK's [HttpClient] so the app pulls in no extra networking dependency.
/// Throws on a non-200 response or timeout — the repository maps that to a
/// failure and the screen offers a retry. [bodyTimeout] bounds the whole
/// body download, so a stalled transfer can't hang forever. A body larger
/// than [maxBytes] throws [HttpException] instead of filling memory.
Future<String> httpGetString(
  Uri url, {
  Duration bodyTimeout = const Duration(seconds: 60),
  int maxBytes = ContentSources.maxSectionBytes,
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.getUrl(url);
    final response = await request.close().timeout(const Duration(seconds: 20));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: url);
    }
    if (response.contentLength > maxBytes) {
      throw HttpException('Body exceeds $maxBytes bytes', uri: url);
    }
    final bytes = BytesBuilder(copy: false);
    await response
        .forEach((chunk) {
          bytes.add(chunk);
          if (bytes.length > maxBytes) {
            throw HttpException('Body exceeds $maxBytes bytes', uri: url);
          }
        })
        .timeout(bodyTimeout);
    return utf8.decode(bytes.takeBytes());
  } finally {
    client.close(force: true);
  }
}
