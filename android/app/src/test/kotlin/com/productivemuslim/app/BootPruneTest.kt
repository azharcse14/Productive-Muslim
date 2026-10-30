package com.productivemuslim.app

import java.time.ZoneId
import java.time.ZonedDateTime
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class BootPruneTest {
    // 2026-10-30 13:00 in Dhaka (UTC+6).
    private val now = ZonedDateTime.of(2026, 10, 30, 13, 0, 0, 0, ZoneId.of("Asia/Dhaka"))
        .toInstant().toEpochMilli()

    private fun stale(at: String, zone: String? = "Asia/Dhaka") = BootPrune.isStale(at, zone, now)

    @Test
    fun missedWhileOffIsDropped() {
        assertTrue(stale("2026-10-30T05:00")) // Fajr, phone was off
        assertTrue(stale("2026-10-30T12:50"))
    }

    @Test
    fun justDueOrFutureIsKept() {
        assertFalse(stale("2026-10-30T12:58")) // within the grace
        assertFalse(stale("2026-10-30T15:30"))
    }

    @Test
    fun readsTheNotificationsOwnZone() {
        // 13:00 Dhaka = 07:00 UTC = 07:00 London (GMT on this date).
        assertFalse(stale("2026-10-30T08:30", "Europe/London"))
        assertTrue(stale("2026-10-30T06:30", "Europe/London"))
    }

    @Test
    fun unknownShapesAreKept() {
        assertFalse(stale("2026-10-30T05:00", null))
        assertFalse(stale("not a date"))
        assertFalse(BootPrune.isStale(null, "Asia/Dhaka", now))
    }
}
