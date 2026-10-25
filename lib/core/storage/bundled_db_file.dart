import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// SQLite sidecar suffixes that must travel with (or die with) a db file.
const _sidecars = ['-journal', '-wal', '-shm'];

/// Location of a bundled, copy-on-first-run SQLite asset: Application
/// Support (not user-visible Documents), optionally in [subdir].
///
/// iOS excludes `Application Support/bundled/` from iCloud backup at launch
/// (AppDelegate), Android excludes it from Auto Backup
/// (`res/xml/backup_rules.xml`) — put only re-creatable files there.
///
/// Installs from before this location existed kept the file in Documents;
/// it is moved across here (see [migrateLegacyDb]).
Future<File> bundledDbFile(String name, {String subdir = ''}) async {
  final support = await getApplicationSupportDirectory();
  final docs = await getApplicationDocumentsDirectory();
  final target = File(p.join(support.path, subdir, name));
  target.parent.createSync(recursive: true);
  migrateLegacyDb(legacy: File(p.join(docs.path, name)), target: target);
  return target;
}

/// Moves [legacy] (and its sidecars) to [target] by rename, so user tables
/// inside it (Quran bookmarks, last read) come along untouched. Sidecars go
/// first: a kill mid-move leaves the main file at [legacy] and the next run
/// finishes the move. If [target] already exists the legacy copy is stale and
/// is deleted.
@visibleForTesting
void migrateLegacyDb({required File legacy, required File target}) {
  if (p.equals(legacy.path, target.path) || !legacy.existsSync()) return;
  if (target.existsSync()) {
    for (final s in ['', ..._sidecars]) {
      final f = File('${legacy.path}$s');
      if (f.existsSync()) f.deleteSync();
    }
    return;
  }
  for (final s in [..._sidecars, '']) {
    final f = File('${legacy.path}$s');
    if (f.existsSync()) _move(f, '${target.path}$s');
  }
}

void _move(File from, String to) {
  try {
    from.renameSync(to);
  } on FileSystemException {
    // Different volume: copy beside the target, rename into place, then drop
    // the source — the target never exists half-written.
    from.copySync('$to.tmp');
    File('$to.tmp').renameSync(to);
    from.deleteSync();
  }
}

/// Writes [bytes] to `<target>.tmp`, lets [prepare] modify that temp file
/// (e.g. carry user tables across), then renames it over [target]. A kill at
/// any point leaves either the old [target] or the complete new one.
Future<void> writeDbAtomically(
  File target,
  List<int> bytes, {
  void Function(String tmpPath)? prepare,
}) async {
  final tmp = File('${target.path}.tmp');
  await tmp.writeAsBytes(bytes, flush: true);
  prepare?.call(tmp.path);
  // Stale sidecars belong to the file being replaced, not the new one.
  for (final s in _sidecars) {
    final f = File('${target.path}$s');
    if (f.existsSync()) f.deleteSync();
  }
  tmp.renameSync(target.path);
}
