// Dev-time script — builds the bundled world-city asset for manual
// location selection (guide §5: name/country/lat/lng/IANA timezone).
//
// Source: GeoNames cities15000 (all cities with population ≥ 15,000),
// licensed CC BY 4.0 (attribution surfaced in About — see DEPENDENCIES.md).
//
// Plus Bangladesh neighbourhoods/towns from OpenStreetMap (ODbL 1.0), kept
// in their own asset so the two licenses never mix in one database.
//
// Usage:  dart run tool/city_db_build.dart
// Output: assets/data/cities.json         — GeoNames (CC BY 4.0)
//         assets/data/places_bd_osm.json  — OpenStreetMap (ODbL 1.0)
//         both JSON arrays of [name, countryCode, lat, lng, ianaTimezone, nameBn?]
// Requires `curl` and `unzip` on PATH (dev machines only).

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

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
      // 1=name 3=alternate names 4=latitude 5=longitude 8=country code
      // 14=population 17=timezone
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
        if (country == 'BD') ?(_bengali(f[3]) ?? _placeBn[f[2]]),
      ]);
    }

    // Largest first so search results rank big cities before namesakes.
    cities.sort((a, b) => (b[5] as int).compareTo(a[5] as int));
    // Population was only needed for ordering — drop it from the asset.
    final compact = [
      for (final c in cities) [...c.take(5), ...c.skip(6)],
    ];

    final osm = _osmBangladesh();
    compact.addAll(_bangladeshAdmin(tmp, osm));
    // OSM fills what GeoNames lacks — skip places GeoNames already has.
    final bd = [
      for (final c in compact)
        if (c[1] == 'BD') c,
    ];
    final osmOnly = [
      for (final o in osm)
        if (!_isDuplicate(o, bd)) o,
    ];
    File(
      'assets/data/places_bd_osm.json',
    ).writeAsStringSync(jsonEncode(osmOnly));
    stdout.writeln('Wrote ${osmOnly.length} OSM places (BD)');

    final out = File('assets/data/cities.json')
      ..parent.createSync(recursive: true);
    out.writeAsStringSync(jsonEncode(compact));
    stdout.writeln(
      'Wrote ${compact.length} cities to ${out.path} '
      '(${(out.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB)',
    );
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

/// BD districts as "X District" and upazilas as "X, District", appended
/// after the population-ordered cities.
List<List<Object>> _bangladeshAdmin(Directory tmp, List<List<Object>> osm) {
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

  final districts = <String, (String, String?)>{
    for (final f in rows)
      if (f[7] == 'ADM2')
        '${f[10]}.${f[11]}': (
          clean(f[1]),
          _bengali(f[3]) ?? _districtBn[clean(f[1])],
        ),
  };
  List<Object> entry(List<String> f, String name, String? bn) => [
    name,
    'BD',
    _round(double.parse(f[4])),
    _round(double.parse(f[5])),
    f[17],
    ?bn,
  ];

  return [
    for (final f in rows)
      if (f[7] == 'ADM2')
        if (districts['${f[10]}.${f[11]}']! case (final en, final bn))
          entry(f, '$en District', bn == null ? null : '$bn জেলা'),
    for (final f in rows)
      // Skip city-corporation zones like "DNCC (Dhaka)".
      if (f[7] == 'ADM3' && !f[1].contains('('))
        if (districts['${f[10]}.${f[11]}'] case final d)
          entry(
            f,
            [clean(f[1]), ?d?.$1].join(', '),
            // Only when the upazila itself has a Bengali name — a bare
            // district name would make "গাজীপুর" list every upazila first.
            switch (_bengali(f[3]) ?? _placeBn[clean(f[1])]) {
              null => null,
              final bn => [bn, ?d?.$2].join(', '),
            },
          ),
    // City neighbourhoods (e.g. Mohammadpur, Dhaka) so a GPS fix names the
    // area, not a farther one; ≥15k ones already came from cities15000.
    // OSM's copy wins where both have one: it carries the Bengali name.
    for (final f in rows)
      if (f[7] == 'PPLX' && (int.tryParse(f[14]) ?? 0) < 15000)
        if (entry(f, f[1], _bengali(f[3]) ?? _placeBn[f[1]]) case final e
            when !_isDuplicate(e, osm))
          e,
  ];
}

const _overpass = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
  'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
];

/// BD cities, towns and city neighbourhoods from OpenStreetMap, deduped
/// among themselves (a place is often both a node and an area).
List<List<Object>> _osmBangladesh() {
  const query =
      '[out:json][timeout:250];'
      'area["ISO3166-1"="BD"][admin_level=2]->.a;'
      'nwr(area.a)[place~"^(city|town|borough|suburb|quarter|neighbourhood)\$"]'
      '[name];out center tags;';
  for (final url in _overpass) {
    stdout.writeln('Querying $url …');
    // Overpass rejects requests without a User-Agent.
    final r = Process.runSync('curl', [
      '-sf', '--max-time', '300', '-A', 'productive-muslim-city-build/1.0',
      url, '--data-urlencode', 'data=$query', //
    ], stdoutEncoding: utf8);
    if (r.exitCode != 0) {
      continue;
    }
    final elements =
        (jsonDecode(r.stdout as String) as Map<String, dynamic>)['elements']
            as List<dynamic>;
    // Nodes first: their point is the place itself, an area's is a centroid.
    elements.sort(
      (a, b) => ((a as Map)['type'] == 'node' ? 0 : 1).compareTo(
        (b as Map)['type'] == 'node' ? 0 : 1,
      ),
    );
    final out = <List<Object>>[];
    for (final e in elements.cast<Map<String, dynamic>>()) {
      final tags = (e['tags'] as Map).cast<String, String>();
      final at = (e['center'] as Map<String, dynamic>?) ?? e;
      final local = tags['name']!;
      final en = tags['name:en'] ?? (_isBengali(local) ? null : local);
      final bn =
          tags['name:bn'] ?? (_isBengali(local) ? local : null) ?? _placeBn[en];
      final name = en ?? bn!;
      // Mapper notes and bare generics ("Bazar"), not place names.
      if (RegExp(r'[(]|^Towards |^My |^(বাজার|স্ট্যান্ড)$').hasMatch(name)) {
        continue;
      }
      final row = <Object>[
        name,
        'BD',
        _round((at['lat'] as num).toDouble()),
        _round((at['lon'] as num).toDouble()),
        'Asia/Dhaka',
        if (bn != null && bn != name) bn,
      ];
      if (!_isDuplicate(row, out)) {
        out.add(row);
      }
    }
    return out;
  }
  throw const ProcessException('curl', [], 'every Overpass endpoint failed');
}

bool _isBengali(String s) => s.runes.any((r) => r >= 0x0980 && r <= 0x09FF);

/// Same place: same folded English or Bengali name within 5 km.
bool _isDuplicate(List<Object> row, List<List<Object>> others) {
  String key(Object name) => (name as String)
      .split(',')
      .first
      .toLowerCase()
      .replaceAll(RegExp('[āâà]'), 'a')
      .replaceAll(RegExp('[īî]'), 'i')
      .replaceAll(RegExp('[ūû]'), 'u')
      .replaceAll(RegExp('[ēê]'), 'e')
      .replaceAll(RegExp('[ōô]'), 'o')
      .replaceAll(RegExp(r'[^a-z\u0980-\u09ff]'), '');
  final en = key(row[0]);
  final bn = row.length > 5 ? key(row[5]) : null;
  for (final o in others) {
    final sameName =
        key(o[0]) == en || (bn != null && o.length > 5 && key(o[5]) == bn);
    if (sameName && _km(row, o) < 5) {
      return true;
    }
  }
  return false;
}

double _km(List<Object> a, List<Object> b) {
  const rad = math.pi / 180;
  final (lat1, lng1) = ((a[2] as double) * rad, (a[3] as double) * rad);
  final (lat2, lng2) = ((b[2] as double) * rad, (b[3] as double) * rad);
  final x = (lng2 - lng1) * math.cos((lat1 + lat2) / 2);
  return 6371 * math.sqrt(x * x + (lat2 - lat1) * (lat2 - lat1));
}

/// First Bengali-script alternate name, minus admin suffixes.
String? _bengali(String alternateNames) {
  for (final name in alternateNames.split(',')) {
    if (name.runes.any((r) => r >= 0x0980 && r <= 0x09FF)) {
      return name.replaceAll(RegExp(r' (জেলা|জিলা|উপজেলা)$'), '').trim();
    }
  }
  return null;
}

/// Districts GeoNames has no Bengali alternate name for.
const _districtBn = {
  'Panchagarh': 'পঞ্চগড়',
  'Thakurgaon': 'ঠাকুরগাঁও',
  'Dinajpur': 'দিনাজপুর',
  'Nilphamari': 'নীলফামারী',
  'Kurigram': 'কুড়িগ্রাম',
  'Rangpur': 'রংপুর',
  'Gaibandha': 'গাইবান্ধা',
  'Naogaon': 'নওগাঁ',
  'Bogra': 'বগুড়া',
  'Chapai Nababganj': 'চাঁপাইনবাবগঞ্জ',
  'Natore': 'নাটোর',
  'Sirajganj': 'সিরাজগঞ্জ',
  'Netrakona': 'নেত্রকোণা',
  'Tangail': 'টাঙ্গাইল',
  'Gazipur': 'গাজীপুর',
  'Kishoregonj': 'কিশোরগঞ্জ',
  'Dhaka': 'ঢাকা',
  'Rajbari': 'রাজবাড়ী',
  'Shariatpur': 'শরীয়তপুর',
  'Madaripur': 'মাদারীপুর',
  "Cox's Bazar": 'কক্সবাজার',
  'Jhenaidah': 'ঝিনাইদহ',
  'Magura': 'মাগুরা',
  'Bagerhat': 'বাগেরহাট',
  'Jhalokati': 'ঝালকাঠি',
  'Patuakhali': 'পটুয়াখালী',
  'Manikganj': 'মানিকগঞ্জ',
};

/// BD cities (by GeoNames ASCII name) and upazilas (by cleaned name)
/// GeoNames has no Bengali alternate name for.
const _placeBn = {
  // cities15000
  'Thakurgaon': 'ঠাকুরগাঁও',
  'Teknaf': 'টেকনাফ',
  'Dohar': 'দোহার',
  'Sunamganj': 'সুনামগঞ্জ',
  'Shibganj': 'শিবগঞ্জ',
  'Satkhira': 'সাতক্ষীরা',
  'Narsingdi': 'নরসিংদী',
  'Sandwip': 'সন্দ্বীপ',
  'Shahzadpur': 'শাহজাদপুর',
  'Ramganj': 'রামগঞ্জ',
  'Pirojpur': 'পিরোজপুর',
  'Panchagarh': 'পঞ্চগড়',
  'Patiya': 'পটিয়া',
  'Parbatipur': 'পার্বতীপুর',
  'Narayanganj': 'নারায়ণগঞ্জ',
  'Nalchiti': 'নলছিটি',
  'Nagarpur': 'নাগরপুর',
  'Nageswari': 'নাগেশ্বরী',
  'Muktagacha': 'মুক্তাগাছা',
  'Mirzapur': 'মির্জাপুর',
  'Maulavi Bazar': 'মৌলভীবাজার',
  'Morrelgonj': 'মোরেলগঞ্জ',
  'Mehendiganj': 'মেহেন্দিগঞ্জ',
  'Mathba': 'মঠবাড়িয়া',
  'Lalmonirhat': 'লালমনিরহাট',
  'Laksham': 'লাকসাম',
  'Kushtia': 'কুষ্টিয়া',
  'Kaliganj': 'কালীগঞ্জ',
  'Jhingergacha': 'ঝিকরগাছা',
  'Joypur Hat': 'জয়পুরহাট',
  'Gaurnadi': 'গৌরনদী',
  'Gafargaon': 'গফরগাঁও',
  'Raipur': 'রায়পুর',
  'Sarankhola': 'শরণখোলা',
  'Ramna Maidan': 'রমনা',
  'Chilmari': 'চিলমারী',
  'Chhagalnaiya': 'ছাগলনাইয়া',
  'Lalmohan': 'লালমোহন',
  'Khagrachhari': 'খাগড়াছড়ি',
  'Chhatak': 'ছাতক',
  'Bhatpara Abhaynagar': 'অভয়নগর',
  'Bheramara': 'ভেড়ামারা',
  'Bandarban': 'বান্দরবান',
  'Kalia': 'কালিয়া',
  'Baniachang': 'বানিয়াচং',
  'Bajitpur': 'বাজিতপুর',
  'Badarganj': 'বদরগঞ্জ',
  'Tungipara': 'টুঙ্গিপাড়া',
  'Sonargaon': 'সোনারগাঁও',
  'Sarishabari': 'সরিষাবাড়ী',
  'Sakhipur': 'সখিপুর',
  'Raojan': 'রাউজান',
  'Phultala': 'ফুলতলা',
  'Palang': 'পালং',
  'Par Naogaon': 'নওগাঁ',
  'Nabinagar': 'নবীনগর',
  'Mohammadpur': 'মোহাম্মদপুর',
  'Matuail': 'মাতুয়াইল',
  'Maijdi': 'মাইজদী',
  'Kesabpur': 'কেশবপুর',
  'Kafrul': 'কাফরুল',
  'Jamirdia': 'জামিরদিয়া',
  'Hajiganj': 'হাজীগঞ্জ',
  'Habirbari': 'হবিরবাড়ী',
  'Gopalganj': 'গোপালগঞ্জ',
  'Faridpur': 'ফরিদপুর',
  'Dukuria': 'ডুকুরিয়া',
  'Dohazari': 'দোহাজারী',
  'Uttar Char Fasson': 'চরফ্যাশন',
  'Char Bhadrasan': 'চরভদ্রাসন',
  'Charamaddi': 'চরামদ্দি',
  'Chandpur': 'চাঁদপুর',
  'Burirchar': 'বুড়িরচর',
  'Bhatara': 'ভাটারা',
  'Bera': 'বেড়া',
  'Burhanuddin': 'বোরহানউদ্দিন',
  'Ayla Patakata': 'আয়লা পাতাকাটা',
  'Ashuganj City': 'আশুগঞ্জ',
  'Satkania': 'সাতকানিয়া',
  "Cox's Bazar": 'কক্সবাজার',
  'Rangamati': 'রাঙ্গামাটি',
  'Jessore': 'যশোর',
  'Brahmanbaria': 'ব্রাহ্মণবাড়িয়া',
  'Pabna': 'পাবনা',
  'Tangail': 'টাঙ্গাইল',
  'Pirgaaj': 'পীরগাছা',
  'Nawabganj': 'নবাবগঞ্জ',
  'Madaripur': 'মাদারীপুর',
  'Sherpur': 'শেরপুর',
  'Kishorganj': 'কিশোরগঞ্জ',
  'Manikganj': 'মানিকগঞ্জ',
  'Hathazari': 'হাটহাজারী',
  'Manikchari': 'মানিকছড়ি',
  'Bhandaria': 'ভান্ডারিয়া',
  'Lama': 'লামা',
  'Taluker Char Doani': 'তালুকের চর দোয়ানী',
  'Natona': 'নাটোনা',
  'Puthia': 'পুঠিয়া',
  'Natore': 'নাটোর',
  'Srimangal': 'শ্রীমঙ্গল',
  'Patuakhali': 'পটুয়াখালী',
  'Dhanmondi': 'ধানমন্ডি',
  'Pallabi': 'পল্লবী',
  'Azimpur': 'আজিমপুর',
  'Demra': 'ডেমরা',
  'Paotana Hat': 'পাওটানা হাট',
  'Karnaphuli': 'কর্ণফুলী',
  'Bhanga': 'ভাঙ্গা',
  'Kaliakair': 'কালিয়াকৈর',
  'Paltan': 'পল্টন',
  'Mirpur Model Thana': 'মিরপুর মডেল থানা',
  'Gulshan': 'গুলশান',
  'Motijheel': 'মতিঝিল',
  'Jessore Cantonment': 'যশোর সেনানিবাস',
  // BD upazilas (ADM3)
  'Araihazar': 'আড়াইহাজার',
  'Ashuganj': 'আশুগঞ্জ',
  'Bancharampur': 'বাঞ্ছারামপুর',
  'Barhatta': 'বারহাট্টা',
  'Barishal Sadar': 'বরিশাল সদর',
  'Barura': 'বরুড়া',
  'Bishwanath': 'বিশ্বনাথ',
  'Boalia': 'বোয়ালিয়া',
  'Brahmanbaria Sadar': 'ব্রাহ্মণবাড়িয়া সদর',
  'Chakaria': 'চকরিয়া',
  'Chandpur Sadar': 'চাঁদপুর সদর',
  'Chatkhil': 'চাটখিল',
  'Chauddagram': 'চৌদ্দগ্রাম',
  'Chitalmari': 'চিতলমারী',
  'Chuadanga Sadar': 'চুয়াডাঙ্গা সদর',
  'Comilla Sadar': 'কুমিল্লা সদর',
  "Cox's Bazar Sadar": 'কক্সবাজার সদর',
  'Cumilla Sadar Dakshin': 'কুমিল্লা সদর দক্ষিণ',
  'Dacope': 'দাকোপ',
  'Daganbhuiyan': 'দাগনভূঞা',
  'Dashmina': 'দশমিনা',
  'Daudkandi': 'দাউদকান্দি',
  'Dawlatpur': 'দৌলতপুর',
  'Delduar': 'দেলদুয়ার',
  'Dhamoirhat': 'ধামইরহাট',
  'Dharampasha': 'ধর্মপাশা',
  'Dhobaura': 'ধোবাউড়া',
  'Durgapur': 'দুর্গাপুর',
  'Fakirhat': 'ফকিরহাট',
  'Faridpur U': 'ফরিদপুর',
  'Fatikchhari': 'ফটিকছড়ি',
  'Fenchuganj': 'ফেঞ্চুগঞ্জ',
  'Feni Sadar': 'ফেনী সদর',
  'Gabtali': 'গাবতলী',
  'Gaffargaon': 'গফরগাঁও',
  'Goalandaghat': 'গোয়ালন্দঘাট',
  'Hakimpur': 'হাকিমপুর',
  'Haripur': 'হরিপুর',
  'Hatiya': 'হাতিয়া',
  'Ishwardi': 'ঈশ্বরদী',
  'Itna': 'ইটনা',
  'Jaintiapur': 'জৈন্তাপুর',
  'Jamalpur': 'জামালপুর',
  'Jhalokati Sadar': 'ঝালকাঠি সদর',
  'Jhikargachha': 'ঝিকরগাছা',
  'Kabirhat': 'কবিরহাট',
  'Kachua': 'কচুয়া',
  'Kathalia': 'কাঠালিয়া',
  'Kawkhali': 'কাউখালী',
  'Keraniganj': 'কেরানীগঞ্জ',
  'Khan Jahan Ali': 'খানজাহান আলী',
  'Kotwali': 'কোতোয়ালী',
  'Lakhai': 'লাখাই',
  'Laksam': 'লাকসাম',
  'Lakshmipur Sadar': 'লক্ষ্মীপুর সদর',
  'Madarganj': 'মাদারগঞ্জ',
  'Mahalchhari': 'মহালছড়ি',
  'Manikgonj Sadar': 'মানিকগঞ্জ সদর',
  'Meghna': 'মেঘনা',
  'Mirsharai': 'মীরসরাই',
  'Mithamain': 'মিঠামইন',
  'Mohanpur': 'মোহনপুর',
  'Moulvibazar Sadar': 'মৌলভীবাজার সদর',
  'Mujibnagar': 'মুজিবনগর',
  'Nawabganj Sadar': 'নবাবগঞ্জ সদর',
  'Nesarabad': 'নেছারাবাদ',
  'Paikgachha': 'পাইকগাছা',
  'Palong': 'পালং',
  'Pekua': 'পেকুয়া',
  'Phulbari': 'ফুলবাড়ী',
  'Pirganj': 'পীরগঞ্জ',
  'Raiganj': 'রায়গঞ্জ',
  'Raipura': 'রায়পুরা',
  'Rajnagar': 'রাজনগর',
  'Ramgarh': 'রামগড়',
  'Ramgati': 'রামগতি',
  'Rangamati Sadar': 'রাঙ্গামাটি সদর',
  'Rangunia': 'রাঙ্গুনিয়া',
  'Saidpur': 'সৈয়দপুর',
  'Sarail': 'সরাইল',
  'Sitakunda': 'সীতাকুণ্ড',
  'Sonagazi': 'সোনাগাজী',
  'South Surma': 'দক্ষিণ সুরমা',
  'Sreemangal': 'শ্রীমঙ্গল',
  'Subarnachar': 'সুবর্ণচর',
  'Tangail Sadar': 'টাঙ্গাইল সদর',
  'Taraganj': 'তারাগঞ্জ',
  'Thanchi': 'থানচি',
  'Titas': 'তিতাস',
  'Tongibari': 'টঙ্গীবাড়ি',
  'Zianagar': 'জিয়ানগর',
  // City neighbourhoods (GeoNames PPLX / OSM) without a Bengali name
  'Ahmad Hossaīn pāra': 'আহমদ হোসেন পাড়া',
  'Amla Para': 'আমলাপাড়া',
  'Askarābad': 'আসকারাবাদ',
  'Bahāddār Hāt': 'বহদ্দারহাট',
  'Bakalia Char': 'বাকলিয়া চর',
  'Bangshal': 'বংশাল',
  'Bank Colony': 'ব্যাংক কলোনি',
  'Basaboo': 'বাসাবো',
  'Biswanāthpur': 'বিশ্বনাথপুর',
  'Chandgaon': 'চান্দগাঁও',
  'Char Rāngāmātia': 'চর রাঙ্গামাটিয়া',
  'Chaudhury pāra': 'চৌধুরী পাড়া',
  'Chikan Dandi': 'চিকনদণ্ডী',
  'Dakshin Chikandandi': 'দক্ষিণ চিকনদণ্ডী',
  'Cornel Hāt': 'কর্নেলহাট',
  'Dakhin Khandakia': 'দক্ষিণ খন্দকিয়া',
  'Dakshin Bakalia': 'দক্ষিণ বাকলিয়া',
  'Dakshin Chāndgaon': 'দক্ষিণ চান্দগাঁও',
  'Dakshin Hālishahar': 'দক্ষিণ হালিশহর',
  'Dakshin Patenga': 'দক্ষিণ পতেঙ্গা',
  'Dakshin Pāhārtali': 'দক্ষিণ পাহাড়তলী',
  'Daulatpur': 'দৌলতপুর',
  'Dewān Hāt': 'দেওয়ানহাট',
  'Diwān Bāzār': 'দেওয়ান বাজার',
  'Double Moorings': 'ডবলমুরিং',
  'Dampāra': 'দামপাড়া',
  'Fakirpāra': 'ফকিরপাড়া',
  'Firingi Bāzār': 'ফিরিঙ্গী বাজার',
  'Hamid Char': 'হামিদচর',
  'Jālālābād': 'জালালাবাদ',
  'Kalibari': 'কালীবাড়ী',
  'Kalyanpur': 'কল্যাণপুর',
  'Kamalapur': 'কমলাপুর',
  'Kānchanpur': 'কাঞ্চনপুর',
  'Khilpāra': 'খিলপাড়া',
  'Khurushkul': 'খুরুশকুল',
  'Kulgaon': 'কুলগাঁও',
  'Lalbagh': 'লালবাগ',
  'Lāldia': 'লালদিয়া',
  'Lāldighi': 'লালদিঘী',
  'Madhya Hālishahar': 'মধ্য হালিশহর',
  'Madhya Hālisharar': 'মধ্য হালিশহর',
  'Mirganj': 'মীরগঞ্জ',
  'Moghbazar': 'মগবাজার',
  'Mohājerpāra': 'মোহাজেরপাড়া',
  'Mugdapara': 'মুগদাপাড়া',
  'Mughaltuli': 'মোগলটুলী',
  'Munshipara': 'মুন্সীপাড়া',
  'Muradpur': 'মুরাদপুর',
  'Narayānpur': 'নারায়ণপুর',
  'New Moorings': 'নিউমুরিং',
  'Nimtala': 'নিমতলা',
  'Paribagh': 'পরীবাগ',
  'Paschim Patenga': 'পশ্চিম পতেঙ্গা',
  'Paschim Sholasahar': 'পশ্চিম ষোলশহর',
  'Postagola': 'পোস্তগোলা',
  'Purba Nāsirābād': 'পূর্ব নাসিরাবাদ',
  'Purba Patenga': 'পূর্ব পতেঙ্গা',
  'Purba Shalashahar': 'পূর্ব ষোলশহর',
  'Purba Sholasahar': 'পূর্ব ষোলশহর',
  'Pāhārtali': 'পাহাড়তলী',
  'Pāikpāra': 'পাইকপাড়া',
  'Pānchlais': 'পাঁচলাইশ',
  'Pāthāntuli': 'পাঠানটুলী',
  'Rajarbagh': 'রাজারবাগ',
  'Rampur': 'রামপুর',
  'Sankarpur': 'শংকরপুর',
  'Sat Masjid': 'সাত মসজিদ',
  'Segunbagan': 'সেগুনবাগান',
  'Sekhpara': 'শেখপাড়া',
  'Shekpāra': 'শেখপাড়া',
  'Sepāipāra': 'সিপাইপাড়া',
  'Shah Ali': 'শাহ আলী',
  'Shaympur': 'শ্যামপুর',
  'Shegunbagicha': 'সেগুনবাগিচা',
  'Sher-e-Bangla Nagor': 'শেরেবাংলা নগর',
  'Tabalchari': 'তবলছড়ি',
  'Tāltala': 'তালতলা',
  'Uttar Bakālia': 'উত্তর বাকলিয়া',
  'Uttar Hālishahar': 'উত্তর হালিশহর',
  'Uttar Patenga': 'উত্তর পতেঙ্গা',
  'Uttar Pāhārtali': 'উত্তর পাহাড়তলী',
  'Zigatola': 'জিগাতলা',
  'Ghosh Para': 'ঘোষপাড়া',
  'Krishnapur': 'কৃষ্ণপুর',
  'Sreerampur': 'শ্রীরামপুর',
  'Salamabad': 'সালামাবাদ',
  'Pirgacha': 'পীরগাছা',
};

double _round(double v) => (v * 10000).roundToDouble() / 10000;

void _run(String cmd, List<String> args) {
  final result = Process.runSync(cmd, args);
  if (result.exitCode != 0) {
    stderr.writeln(result.stderr);
    throw ProcessException(cmd, args, 'exit ${result.exitCode}');
  }
}
