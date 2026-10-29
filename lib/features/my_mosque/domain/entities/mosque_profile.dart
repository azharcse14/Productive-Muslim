import '../../../settings/domain/entities/prayer_params.dart';
import 'jamaat_config.dart';

/// One mosque's jamaat configuration (design §4.9): user may keep several
/// (home/work) with one active.
final class MosqueProfile {
  const MosqueProfile({
    required this.id,
    required this.name,
    this.entries = const {},
    this.jumuah,
  });

  /// New profiles default Maghrib to offset +5 minutes (design §4.9).
  factory MosqueProfile.create({required String id, required String name}) =>
      MosqueProfile(
        id: id,
        name: name,
        entries: const {Prayer.maghrib: OffsetJamaat(Duration(minutes: 5))},
      );

  /// Stable identity — survives renames; [copyWith] never changes it.
  final String id;
  final String name;

  /// Per-prayer jamaat settings; missing key = unset.
  final Map<Prayer, JamaatEntry> entries;

  /// Optional Friday Jumu'ah jamaat time (null = use Dhuhr's entry).
  final ClockTime? jumuah;

  JamaatConfig get config => JamaatConfig(entries, jumuah);

  /// [clearJumuah] drops the Jumu'ah time ([jumuah] null means "keep").
  MosqueProfile copyWith({
    String? name,
    Map<Prayer, JamaatEntry>? entries,
    ClockTime? jumuah,
    bool clearJumuah = false,
  }) => MosqueProfile(
    id: id,
    name: name ?? this.name,
    entries: entries ?? this.entries,
    jumuah: clearJumuah ? null : jumuah ?? this.jumuah,
  );

  @override
  bool operator ==(Object other) {
    if (other is! MosqueProfile ||
        other.id != id ||
        other.name != name ||
        other.jumuah != jumuah ||
        other.entries.length != entries.length) {
      return false;
    }
    for (final entry in entries.entries) {
      if (other.entries[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    jumuah,
    Object.hashAllUnordered(
      entries.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}
