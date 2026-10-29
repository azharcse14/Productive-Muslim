package com.productivemuslim.app

/**
 * Pure (Context-free) decisions for [ProductiveMuslimWidgetProvider]: what
 * to show at [now] from the pushed `widget_*` strings, and when to re-render.
 * The iOS widget mirrors this in `ProductiveMuslimWidget.swift`.
 *
 * Keys (see `widget_payload.dart`):
 *  - `widget_schedule`: `epochMillis<TAB>prayer<TAB>time` per prayer start.
 *  - `widget_strips`: `startMillis<TAB>endMillis<TAB>strip` per day.
 *  - Legacy (pushed by app versions before the 7-day schedule, read until the
 *    first push after an upgrade): `widget_times`, `widget_times_next`,
 *    `widget_day_flip`.
 */
object WidgetSchedule {

    /** What the configured widget shows; [Stale] once the pushed starts run out. */
    sealed interface View {
        data class Next(val prayer: String, val time: String, val strip: String) : View
        data object Stale : View
    }

    private data class Strip(val start: Long, val end: Long, val text: String)

    fun view(data: Map<String, String>, now: Long): View {
        val next = starts(data).firstOrNull { it.first > now } ?: return View.Stale
        val strip = strips(data).firstOrNull { now >= it.start && now < it.end }
        return View.Next(next.second, next.third, strip?.text ?: "")
    }

    /** When the view next changes (a prayer start or a day boundary); null when stale. */
    fun nextChange(data: Map<String, String>, now: Long): Long? {
        val start = starts(data).firstOrNull { it.first > now }?.first ?: return null
        val boundary = strips(data).map { it.start }.firstOrNull { it > now }
        return listOfNotNull(start, boundary).min()
    }

    private fun starts(data: Map<String, String>): List<Triple<Long, String, String>> =
        data["widget_schedule"].orEmpty().lines().mapNotNull { line ->
            val parts = line.split('\t')
            val millis = parts[0].toLongOrNull()
            if (millis == null || parts.size < 3) null else Triple(millis, parts[1], parts[2])
        }

    private fun strips(data: Map<String, String>): List<Strip> {
        val raw = data["widget_strips"].orEmpty()
        if (raw.isNotEmpty()) {
            return raw.lines().mapNotNull { line ->
                val parts = line.split('\t')
                val start = parts[0].toLongOrNull()
                val end = parts.getOrNull(1)?.toLongOrNull()
                if (start == null || end == null || parts.size < 3) null
                else Strip(start, end, parts[2])
            }
        }
        // Legacy: today's strip until the day flip, then tomorrow's.
        val today = data["widget_times"].orEmpty()
        val tomorrow = data["widget_times_next"].orEmpty()
        val flip = data["widget_day_flip"]?.toLongOrNull() ?: 0L
        if (flip <= 0L || tomorrow.isEmpty()) {
            return listOf(Strip(Long.MIN_VALUE, Long.MAX_VALUE, today))
        }
        return listOf(
            Strip(Long.MIN_VALUE, flip, today),
            Strip(flip, Long.MAX_VALUE, tomorrow),
        )
    }
}
