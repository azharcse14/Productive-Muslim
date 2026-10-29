package com.productivemuslim.app

/**
 * The pure decisions behind [JamaatFocus]: no Context, so JVM unit tests
 * cover them (FocusPlanTest). A window is (start, end) in epoch ms;
 * end = -1 means "until the user ends it".
 */
object FocusPlan {
    /** A "until I end it" session may start this late (alarm delayed, phone off). */
    const val MANUAL_GRACE_MS = 30 * 60 * 1000L

    /** Windows from the Dart plan ([[start, end], …]); malformed entries dropped. */
    fun fromArgs(windows: Any?): List<Pair<Long, Long>> =
        (windows as? List<*>).orEmpty().mapNotNull { w ->
            val pair = w as? List<*> ?: return@mapNotNull null
            val from = (pair.getOrNull(0) as? Number)?.toLong() ?: return@mapNotNull null
            val to = (pair.getOrNull(1) as? Number)?.toLong() ?: return@mapNotNull null
            from to to
        }

    fun encode(windows: List<Pair<Long, Long>>): String =
        windows.joinToString(";") { "${it.first},${it.second}" }

    /** Stored "start,end;start,end"; corrupt entries dropped, never thrown. */
    fun parse(raw: String?): List<Pair<Long, Long>> =
        raw.orEmpty().split(';').mapNotNull {
            val parts = it.split(',')
            if (parts.size != 2) return@mapNotNull null
            val from = parts[0].toLongOrNull() ?: return@mapNotNull null
            val to = parts[1].toLongOrNull() ?: return@mapNotNull null
            from to to
        }

    /** The window to start now: open, and not the one started last ([lastStart]). */
    fun due(windows: List<Pair<Long, Long>>, now: Long, lastStart: Long): Pair<Long, Long>? =
        windows.firstOrNull { (from, to) ->
            val closes = if (to > 0) to else from + MANUAL_GRACE_MS
            now >= from && from != lastStart && now < closes
        }

    /** Next alarm: the earliest future start, or the running session's end ([until]). */
    fun nextAlarm(windows: List<Pair<Long, Long>>, until: Long, now: Long): Long? =
        (windows.map { it.first } + until).filter { it > now }.minOrNull()

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
