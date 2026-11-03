/// Read port onto the fasting tracker's log: whether the civil [day] is
/// logged as fasted. Wired in the composition root, so Ramadan never
/// imports the fasting feature.
typedef IsDayFasted = bool Function(DateTime day);
