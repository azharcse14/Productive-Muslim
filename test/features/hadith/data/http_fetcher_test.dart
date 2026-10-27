import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/hadith/data/http_fetcher.dart';

void main() {
  late HttpServer server;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  });
  tearDown(() => server.close(force: true));

  Uri url(String path) => Uri.parse('http://127.0.0.1:${server.port}$path');

  test('returns the body', () async {
    server.listen((req) async {
      req.response.write('hello');
      await req.response.close();
    });
    expect(await httpGetString(url('/ok')), 'hello');
  });

  test('a body that stalls mid-download times out', () async {
    server.listen((req) async {
      req.response
        ..contentLength = 100
        ..write('partial');
      await req.response.flush(); // headers + some bytes, then nothing
    });
    await expectLater(
      httpGetString(
        url('/stall'),
        bodyTimeout: const Duration(milliseconds: 200),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });
}
