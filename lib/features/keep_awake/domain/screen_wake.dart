/// Keeps the display from dimming and locking while a reading or dhikr
/// screen is open (Quran reader, tasbih). Screens call `hold(on: true)` when
/// they open and `hold(on: false)` when they close; overlapping holds are
/// counted, so the flag drops only when the last one is released.
abstract interface class ScreenWake {
  Future<void> hold({required bool on});
}
