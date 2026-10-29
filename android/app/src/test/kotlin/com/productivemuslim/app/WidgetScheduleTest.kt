package com.productivemuslim.app

import com.productivemuslim.app.WidgetSchedule.View
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WidgetScheduleTest {

    private val day = 86_400_000L

    /** Two days (0 and 1) with prayers at 5h and 13h, plus the Fajr after. */
    private val data = mapOf(
        "widget_schedule" to listOf(
            "${-4 * HOUR}\tisha\t20:00",
            "${5 * HOUR}\tfajr\t5:00",
            "${13 * HOUR}\tdhuhr\t13:00",
            "${day + 5 * HOUR}\tfajr\t5:01",
            "${day + 13 * HOUR}\tdhuhr\t13:01",
            "${2 * day + 5 * HOUR}\tfajr\t5:02",
        ).joinToString("\n"),
        "widget_strips" to "0\t$day\tday0\n$day\t${2 * day}\tday1",
    )

    @Test
    fun picksFirstStartAheadAndTheStripOfTheCurrentDay() {
        assertEquals(View.Next("fajr", "5:00", "day0"), WidgetSchedule.view(data, HOUR))
        assertEquals(View.Next("dhuhr", "13:00", "day0"), WidgetSchedule.view(data, 5 * HOUR))
        // After the day's last start: tomorrow's Fajr, still today's strip.
        assertEquals(View.Next("fajr", "5:01", "day0"), WidgetSchedule.view(data, 20 * HOUR))
        // Midnight swaps the strip.
        assertEquals(View.Next("fajr", "5:01", "day1"), WidgetSchedule.view(data, day))
    }

    @Test
    fun afterMidnightIshaFromTheDayBefore() {
        assertEquals(View.Next("isha", "20:00", ""), WidgetSchedule.view(data, -5 * HOUR))
    }

    @Test
    fun pastTheLastStartIsStaleNeverOldTimes() {
        assertEquals(View.Stale, WidgetSchedule.view(data, 2 * day + 5 * HOUR))
        assertEquals(View.Stale, WidgetSchedule.view(data, 10 * day))
        assertNull(WidgetSchedule.nextChange(data, 10 * day))
        assertEquals(View.Stale, WidgetSchedule.view(emptyMap(), 0))
    }

    @Test
    fun nextChangeIsTheNextStartOrDayBoundary() {
        assertEquals(5 * HOUR, WidgetSchedule.nextChange(data, HOUR))
        assertEquals(day, WidgetSchedule.nextChange(data, 20 * HOUR))
        // Between the last strip's end and the final Fajr: that Fajr.
        assertEquals(2 * day + 5 * HOUR, WidgetSchedule.nextChange(data, 2 * day + HOUR))
    }

    @Test
    fun outsideEveryStripShowsNoStrip() {
        assertEquals(View.Next("fajr", "5:02", ""), WidgetSchedule.view(data, 2 * day + HOUR))
    }

    @Test
    fun malformedLinesAreSkipped() {
        val bad = mapOf(
            "widget_schedule" to "x\tfajr\t5:00\n${5 * HOUR}\tfajr\n${13 * HOUR}\tdhuhr\t13:00\n",
            "widget_strips" to "0\tx\tbroken\n0\t$day\tday0",
        )
        assertEquals(View.Next("dhuhr", "13:00", "day0"), WidgetSchedule.view(bad, HOUR))
    }

    @Test
    fun legacyKeysBeforeTheFirstPushAfterAnUpgrade() {
        val legacy = mapOf(
            "widget_schedule" to data.getValue("widget_schedule"),
            "widget_times" to "today",
            "widget_times_next" to "tomorrow",
            "widget_day_flip" to "$day",
        )
        assertEquals(View.Next("fajr", "5:00", "today"), WidgetSchedule.view(legacy, HOUR))
        assertEquals(View.Next("fajr", "5:01", "tomorrow"), WidgetSchedule.view(legacy, day))
        assertEquals(day, WidgetSchedule.nextChange(legacy, 20 * HOUR))
        // No flip pushed: today's strip throughout.
        val noFlip = legacy - "widget_day_flip"
        assertEquals(View.Next("fajr", "5:01", "today"), WidgetSchedule.view(noFlip, day))
    }

    private companion object {
        const val HOUR = 3_600_000L
    }
}
