package com.productivemuslim.app

import com.productivemuslim.app.FocusPlan.MANUAL_GRACE_MS
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class FocusPlanTest {
    private val windows = listOf(1_000L to 2_000L, 5_000L to 6_000L)

    @Test
    fun dueWindowIsTheOpenOne() {
        assertNull(FocusPlan.due(windows, 999, 0))
        assertEquals(1_000L to 2_000L, FocusPlan.due(windows, 1_000, 0))
        assertEquals(1_000L to 2_000L, FocusPlan.due(windows, 1_999, 0))
        assertNull(FocusPlan.due(windows, 2_000, 0))
        assertEquals(5_000L to 6_000L, FocusPlan.due(windows, 5_500, 0))
    }

    @Test
    fun manualSessionStartsOnlyWithinTheGrace() {
        val manual = listOf(1_000L to -1L)
        assertEquals(1_000L to -1L, FocusPlan.due(manual, 1_000, 0))
        assertEquals(1_000L to -1L, FocusPlan.due(manual, 1_000 + MANUAL_GRACE_MS - 1, 0))
        assertNull(FocusPlan.due(manual, 1_000 + MANUAL_GRACE_MS, 0))
    }

    @Test
    fun theSameStartNeverRestarts() {
        assertNull(FocusPlan.due(windows, 1_500, lastStart = 1_000))
        assertNull(FocusPlan.due(listOf(1_000L to -1L), 1_500, lastStart = 1_000))
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
            listOf(1L to 2L, 3L to -1L),
            FocusPlan.parse("1,2;x,4;5;;6,7,8;3,-1;9,"),
        )
        assertEquals(emptyList<Pair<Long, Long>>(), FocusPlan.parse(""))
        assertEquals(emptyList<Pair<Long, Long>>(), FocusPlan.parse(null))
    }

    @Test
    fun malformedPlanEntriesAreSkippedAndRoundTrip() {
        val parsed = FocusPlan.fromArgs(
            listOf(listOf(1, 2L), listOf(3.0), "x", listOf("4", 5), null, listOf(6L, -1))
        )
        assertEquals(listOf(1L to 2L, 6L to -1L), parsed)
        assertEquals(parsed, FocusPlan.parse(FocusPlan.encode(parsed)))
        assertEquals(emptyList<Pair<Long, Long>>(), FocusPlan.fromArgs("nope"))
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
}
