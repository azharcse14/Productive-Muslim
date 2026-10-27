// Dev-time script — builds the bundled world-city asset for manual
// location selection (guide §5: name/country/lat/lng/IANA timezone).
//
// Source: GeoNames cities15000 (all cities with population ≥ 15,000),
// licensed CC BY 4.0 (attribution surfaced in About — see DEPENDENCIES.md).
//
// Usage:  dart run tool/city_db_build.dart
// Output: assets/data/cities.json  — JSON array of
//         [name, countryCode, lat, lng, ianaTimezone]
// Requires `curl` and `unzip` on PATH (dev machines only).

import 'dart:convert';
import 'dart:io';

const _dumpUrl = 'https://download.geonames.org/export/dump/cities15000.zip';

// Full Bangladesh dump: cities15000 misses many district towns, and
// upazilas (ADM3) are what BD users expect to pick.
const _bdUrl = 'https://download.geonames.org/export/dump/BD.zip';

Future<void> main() async {
  final tmp = Directory.systemTemp.createTempSync('productive_muslim_cities');
  try {
    final zipPath = '${tmp.path}/cities15000.zip';
    stdout.writeln('Downloading $_dumpUrl …');
    _run('curl', ['-sfL', '-o', zipPath, _dumpUrl]);
    _run('unzip', ['-o', '-q', zipPath, '-d', tmp.path]);

    final lines = File('${tmp.path}/cities15000.txt').readAsLinesSync();
    final cities = <List<Object>>[];
    for (final line in lines) {
      // GeoNames tab-separated columns:
      // 1=name 4=latitude 5=longitude 8=country code 14=population 17=timezone
      final f = line.split('\t');
      if (f.length < 18) {
        continue;
      }
      final name = f[1];
      final lat = double.tryParse(f[4]);
      final lng = double.tryParse(f[5]);
      final country = f[8];
      final population = int.tryParse(f[14]) ?? 0;
      final tz = f[17];
      if (lat == null || lng == null || tz.isEmpty || name.isEmpty) {
        continue;
      }
      cities.add([
        name,
        country,
        _round(lat),
        _round(lng),
        tz,
        population,
      ]);
    }

    // Largest first so search results rank big cities before namesakes.
    cities.sort((a, b) => (b[5] as int).compareTo(a[5] as int));
    // Population was only needed for ordering — drop it from the asset.
    final compact = [
      for (final c in cities) [c[0], c[1], c[2], c[3], c[4]],
    ];

    compact.addAll(_bangladeshAdmin(tmp));

    final out = File('assets/data/cities.json')
      ..parent.createSync(recursive: true);
    out.writeAsStringSync(jsonEncode(compact));
    stdout.writeln('Wrote ${compact.length} cities to ${out.path} '
        '(${(out.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB)');
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

/// BD districts as "X District" and upazilas as "X, District", appended
/// after the population-ordered cities.
List<List<Object>> _bangladeshAdmin(Directory tmp) {
  final zipPath = '${tmp.path}/BD.zip';
  stdout.writeln('Downloading $_bdUrl …');
  _run('curl', ['-sfL', '-o', zipPath, _bdUrl]);
  _run('unzip', ['-o', '-q', zipPath, '-d', tmp.path]);

  // 7=feature code 10=admin1 11=admin2
  final rows = [
    for (final line in File('${tmp.path}/BD.txt').readAsLinesSync())
      line.split('\t'),
  ].where((f) => f.length >= 18 && f[17].isNotEmpty).toList();

  String clean(String name) => name
      .replaceAll(RegExp(r' (Zila|District|Upazila Parishad|Upazila)$'), '')
      .replaceAll(RegExp(r' S\.$'), ' Sadar');

  final districts = <String, String>{
    for (final f in rows)
      if (f[7] == 'ADM2') '${f[10]}.${f[11]}': clean(f[1]),
  };
  List<Object> entry(List<String> f, String name) =>
      [name, 'BD', _round(double.parse(f[4])), _round(double.parse(f[5])), f[17]];

  return [
    for (final f in rows)
      if (f[7] == 'ADM2') entry(f, '${clean(f[1])} District'),
    for (final f in rows)
      // Skip city-corporation zones like "DNCC (Dhaka)".
      if (f[7] == 'ADM3' && !f[1].contains('('))
        entry(f, [clean(f[1]), ?districts['${f[10]}.${f[11]}']].join(', ')),
  ];
}

double _round(double v) => (v * 10000).roundToDouble() / 10000;

void _run(String cmd, List<String> args) {
  final result = Process.runSync(cmd, args);
  if (result.exitCode != 0) {
    stderr.writeln(result.stderr);
    throw ProcessException(cmd, args, 'exit ${result.exitCode}');
  }
}
