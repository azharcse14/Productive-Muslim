package com.productivemuslim.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class DirectBootPlanTest {
    private fun entry(id: Int, at: Long) = DirectBootPlan.Entry(
        id, at, "productive_muslim_azan", "ফজর ৪:৫২", "Time for Fajr", "/home?prayer=fajr",
    )

    @Test
    fun roundTripsEveryField() {
        val e = entry(7, 1_800_000_000_000).copy(title = "", body = "a\nb")
        assertEquals(e, DirectBootPlan.decode(DirectBootPlan.encode(e)))
    }

    @Test
    fun malformedEntriesAreSkipped() {
        assertNull(DirectBootPlan.decode(""))
        assertNull(DirectBootPlan.decode("x\u00001\u0000c\u0000t\u0000b\u0000p"))
        assertNull(DirectBootPlan.decode("1\u00002\u0000c"))
    }

    @Test
    fun armsTheNotYetMissedEarliestFirst() {
        val now = 1_000_000_000L
        val missed = entry(1, now - BootPrune.GRACE_MS - 1)
        val justDue = entry(2, now - 60_000)
        val later = entry(3, now + 3_600_000)
        val soon = entry(4, now + 60_000)
        assertEquals(
            listOf(justDue, soon, later),
            DirectBootPlan.toArm(listOf(later, missed, soon, justDue), now),
        )
    }
}
