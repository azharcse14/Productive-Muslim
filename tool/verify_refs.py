"""Verify refs against the app's bundled DBs.

  python3 -I tool/verify_refs.py hadith bukhari 3470        # English text of Bukhari 3470
  python3 -I tool/verify_refs.py hadith muslim 2354
  python3 -I tool/verify_refs.py grep bukhari "ninety-nine"  # find hadith numbers by phrase
  python3 -I tool/verify_refs.py quran 12 4 [7]             # ayahs 12:4..7 (en + bn)
Books: bukhari muslim abudawud tirmidhi nasai ibnmajah malik nawawi qudsi
"""
import gzip, json, sqlite3, sys, zlib

ROOT = 'assets/data/'  # run from the repo root


def blob(b):
    try:
        return json.loads(gzip.decompress(b))
    except OSError:
        return json.loads(zlib.decompress(b))


def hadiths(book):
    c = sqlite3.connect(ROOT + 'hadith.db')
    for (b,) in c.execute(
            "select data from hadith_section where edition=? order by section",
            ('eng-' + book,)):
        yield from blob(b)


cmd = sys.argv[1]
if cmd == 'hadith':
    n = sys.argv[3]
    hits = [h for h in hadiths(sys.argv[2]) if str(h['n']) == n]
    for h in hits:
        print(h['n'], h.get('g', ''), '\n', h['t'])
    if not hits:
        print('NOT FOUND')
elif cmd == 'grep':
    q = sys.argv[3].lower()
    for h in hadiths(sys.argv[2]):
        if q in h['t'].lower():
            print(h['n'], '|', h['t'][:160].replace('\n', ' '))
elif cmd == 'quran':
    s, a = int(sys.argv[2]), int(sys.argv[3])
    b = int(sys.argv[4]) if len(sys.argv) > 4 else a
    c = sqlite3.connect(ROOT + 'quran.db')
    for row in c.execute(
            "select surah, number, translation_en, translation_bn from ayahs "
            "where surah=? and number between ? and ? order by number", (s, a, b)):
        print(f'{row[0]}:{row[1]}  {row[2]}\n        {row[3]}')
