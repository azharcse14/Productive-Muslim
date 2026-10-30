package com.productivemuslim.app

import com.productivemuslim.app.FocusPlan.MANUAL_GRACE_MS
import com.productivemuslim.app.FocusPlan.Window
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class FocusPlanTest {
    private fun w(start: Long, end: Long, key: Long = 0L) = Window(start, end, key)

    private val windows = listOf(w(1_000, 2_000), w(5_000, 6_000))

    @Test
    fun dueWindowIsTheOpenOne() {
        assertNull(FocusPlan.due(windows, 999, 0))
        assertEquals(w(1_000, 2_000), FocusPlan.due(windows, 1_000, 0))
        assertEquals(w(1_000, 2_000), FocusPlan.due(windows, 1_999, 0))
        assertNull(FocusPlan.due(windows, 2_000, 0))
        assertEquals(w(5_000, 6_000), FocusPlan.due(windows, 5_500, 0))
    }

    @Test
    fun manualSessionStartsOnlyWithinTheGrace() {
        val manual = listOf(w(1_000, -1))
        assertEquals(w(1_000, -1), FocusPlan.due(manual, 1_000, 0))
        assertEquals(w(1_000, -1), FocusPlan.due(manual, 1_000 + MANUAL_GRACE_MS - 1, 0))
        assertNull(FocusPlan.due(manual, 1_000 + MANUAL_GRACE_MS, 0))
    }

    @Test
    fun theSameStartNeverRestarts() {
        assertNull(FocusPlan.due(windows, 1_500, lastStart = 1_000))
        assertNull(FocusPlan.due(listOf(w(1_000, -1)), 1_500, lastStart = 1_000))
    }

    @Test
    fun aJamaatMovedMidSessionDoesNotRunAgain() {
        // Key 1 ran from 1000; the re-sent plan moved it to 1500 (and the
        // user may have ended it early): it must not start again.
        val moved = listOf(w(1_500, 2_500, key = 1), w(5_000, 6_000, key = 2))
        assertNull(FocusPlan.due(moved, 1_600, lastStart = 1_000, lastKey = 1))
        assertEquals(
            w(5_000, 6_000, key = 2),
            FocusPlan.due(moved, 5_000, lastStart = 1_000, lastKey = 1),
        )
    }

    @Test
    fun theNextJamaatStartsRightAfterOrInsideThePreviousOne() {
        // Maghrib (key 1) ran 1000..2000; Isha (key 2) opened at 1800,
        // before Maghrib's end alarm fired (late, at 2100).
        val plan = listOf(w(1_000, 2_000, key = 1), w(1_800, 3_000, key = 2))
        assertEquals(
            w(1_800, 3_000, key = 2),
            FocusPlan.due(plan, 2_100, lastStart = 1_000, lastKey = 1),
        )
    }

    @Test
    fun nextAlarmIsTheEarliestFutureStartOrTheActiveEnd() {
        assertEquals(1_000L, FocusPlan.nextAlarm(windows, 0, 0))
        assertEquals(5_000L, FocusPlan.nextAlarm(windows, 0, 1_000))
        // Running until 2000: its end comes before the next start.
        assertEquals(2_000L, FocusPlan.nextAlarm(windows, 2_000, 1_500))
        // Manual session (until = -1): only starts count.
        assertEquals(5_000L, FocusPlan.nextAlarm(windows, -1, 1_500))
        assertNull(FocusPlan.nextAlarm(windows, 0, 6_000))
    }

    @Test
    fun malformedStoredEntriesAreSkipped() {
        assertEquals(
            listOf(w(1, 2), w(6, 7, key = 8), w(3, -1)),
            FocusPlan.parse("1,2;x,4;5;;6,7,8;3,-1;9,;1,2,y;1,2,3,4"),
        )
        assertEquals(emptyList<Window>(), FocusPlan.parse(""))
        assertEquals(emptyList<Window>(), FocusPlan.parse(null))
    }

    @Test
    fun malformedPlanEntriesAreSkippedAndRoundTrip() {
        val parsed = FocusPlan.fromArgs(
            listOf(
                listOf(1, 2L), listOf(3.0), "x", listOf("4", 5), null,
                listOf(6L, -1), listOf(7L, 8L, 202606151L),
            )
        )
        assertEquals(listOf(w(1, 2), w(6, -1), w(7, 8, key = 202606151)), parsed)
        assertEquals(parsed, FocusPlan.parse(FocusPlan.encode(parsed)))
        assertEquals(emptyList<Window>(), FocusPlan.fromArgs("nope"))
    }

    private fun allowed(pkg: String) = FocusPlan.allowed(
        pkg,
        own = "com.productivemuslim.app",
        dialer = "com.google.android.dialer",
        ime = "com.google.android.inputmethod.latin/com.android.inputmethod.latin.LatinIME",
        clocks = setOf("com.google.android.deskclock"),
    )

    @Test
    fun allowlist() {
        assertTrue(allowed("com.productivemuslim.app"))
        assertTrue(allowed("com.android.systemui"))
        assertTrue(allowed("com.android.settings"))
        assertTrue(allowed("com.android.vending"))
        assertTrue(allowed("com.google.android.dialer"))
        assertTrue(allowed("com.google.android.inputmethod.latin"))
        assertTrue(allowed("com.google.android.deskclock"))
        assertFalse(allowed("com.instagram.android"))
        // Prefix of the IME package is not the IME.
        assertFalse(allowed("com.google.android.inputmethod"))
    }

    @Test
    fun allowlistWithoutDialerOrKeyboard() {
        assertFalse(FocusPlan.allowed("com.x", "own", dialer = null, ime = null, clocks = emptySet()))
    }

    @Test
    fun inexactAlarmsHopHalfwayUntilClose() {
        val min = 60_000L
        // 8 h away: halfway, so a deferral can't overshoot the window.
        assertEquals(4 * 60 * min, FocusPlan.inexactHop(8 * 60 * min, 0L))
        // Within 10 min: aim at the target itself.
        assertEquals(10 * min, FocusPlan.inexactHop(10 * min, 0L))
        // A worst-case (75%) deferral of every hop still lands before the start.
        var now = 0L
        val at = 8 * 60 * min
        var hops = 0
        while (now < at) {
            val armed = FocusPlan.inexactHop(at, now)
            if (armed == at) break
            now = armed + (armed - now) * 3 / 4
            hops++
        }
        assertTrue(now < at)
        assertTrue(hops < 12)
    }
}
