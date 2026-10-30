package com.productivemuslim.app

/**
 * The pure decisions behind [JamaatFocus]: no Context, so JVM unit tests
 * cover them (FocusPlanTest). A window is (start, end) in epoch ms;
 * end = -1 means "until the user ends it". [Window.key] names the jamaat
 * (prayer day + prayer, from Dart) so a re-sent plan that moves it is still
 * recognised as the same session; 0 = unknown (older stored plans).
 */
object FocusPlan {
    data class Window(val start: Long, val end: Long, val key: Long = 0L)

    /** A "until I end it" session may start this late (alarm delayed, phone off). */
    const val MANUAL_GRACE_MS = 30 * 60 * 1000L

    /** Windows from the Dart plan ([[start, end, key?], …]); malformed entries dropped. */
    fun fromArgs(windows: Any?): List<Window> =
        (windows as? List<*>).orEmpty().mapNotNull { w ->
            val list = w as? List<*> ?: return@mapNotNull null
            val from = (list.getOrNull(0) as? Number)?.toLong() ?: return@mapNotNull null
            val to = (list.getOrNull(1) as? Number)?.toLong() ?: return@mapNotNull null
            Window(from, to, (list.getOrNull(2) as? Number)?.toLong() ?: 0L)
        }

    fun encode(windows: List<Window>): String =
        windows.joinToString(";") { "${it.start},${it.end},${it.key}" }

    /** Stored "start,end[,key];…"; corrupt entries dropped, never thrown. */
    fun parse(raw: String?): List<Window> =
        raw.orEmpty().split(';').mapNotNull {
            val parts = it.split(',')
            if (parts.size !in 2..3) return@mapNotNull null
            val from = parts[0].toLongOrNull() ?: return@mapNotNull null
            val to = parts[1].toLongOrNull() ?: return@mapNotNull null
            val key = if (parts.size == 3) parts[2].toLongOrNull() ?: return@mapNotNull null else 0L
            Window(from, to, key)
        }

    /**
     * The window to start now: open, and not the session that ran last —
     * same start ([lastStart]) or same jamaat ([lastKey]), so a plan re-sent
     * mid-session (lead, length or jamaat time changed) can't run it twice,
     * while the next prayer's window still starts on time.
     */
    fun due(windows: List<Window>, now: Long, lastStart: Long, lastKey: Long = 0L): Window? =
        windows.firstOrNull { w ->
            val closes = if (w.end > 0) w.end else w.start + MANUAL_GRACE_MS
            now >= w.start && w.start != lastStart &&
                (w.key == 0L || w.key != lastKey) && now < closes
        }

    /** Next alarm: the earliest future start, or the running session's end ([until]). */
    fun nextAlarm(windows: List<Window>, until: Long, now: Long): Long? =
        (windows.map { it.start } + until).filter { it > now }.minOrNull()

    private val SYSTEM = setOf(
        "android", "com.android.systemui",
        "com.android.server.telecom", "com.android.phone", "com.android.emergency",
        "com.android.settings", "com.android.packageinstaller",
        "com.google.android.packageinstaller", "com.android.vending",
    )

    /**
     * Never covered: this app ([own]), the shade, calls, the dialer, the
     * keyboard ([ime] = "pkg/.Service"), alarm apps ([clocks]) — and Settings,
     * the package installer and Play, so the user can always turn the service
     * off or uninstall (Play accessibility policy).
     */
    fun allowed(
        pkg: String,
        own: String,
        dialer: String?,
        ime: String?,
        clocks: Set<String>,
    ): Boolean =
        pkg == own || pkg in SYSTEM || pkg == dialer || pkg in clocks ||
            ime?.startsWith("$pkg/") == true
}
