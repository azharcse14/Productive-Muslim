package com.productivemuslim.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NafsCountdownTest {
    private val c = NafsCountdown(5_000)

    @Test
    fun firesOnceAfterArming() {
        assertTrue(c.arm(1_000))
        assertEquals(6_000, c.endsAt)
        assertTrue(c.fire())
        assertFalse(c.armed)
        assertFalse(c.fire()) // a second post can't lock again
    }

    @Test
    fun cancelStopsTheLock() {
        c.arm(0)
        assertTrue(c.cancel())
        assertFalse(c.fire())
        assertFalse(c.cancel())
    }

    @Test
    fun shakesDuringCountdownNeitherRestartNorStack() {
        assertTrue(c.arm(0))
        assertFalse(c.arm(3_000))
        assertEquals(5_000, c.endsAt)
        assertTrue(c.fire())
        assertTrue(c.arm(10_000)) // a new countdown after it's done
    }

    @Test
    fun secondsCountDownRoundedUp() {
        assertEquals(0, c.secondsLeft(0))
        c.arm(0)
        assertEquals(5, c.secondsLeft(0))
        assertEquals(5, c.secondsLeft(1))
        assertEquals(1, c.secondsLeft(4_999))
        assertEquals(0, c.secondsLeft(5_000))
        assertEquals(0, c.secondsLeft(9_000))
    }

    @Test
    fun labelFillsSecondsInAppDigits() {
        c.arm(0)
        assertEquals("Locking in 3 s", c.label("Locking in {seconds} s", 2_500, ""))
        assertEquals("৩ সেকেন্ডে", c.label("{seconds} সেকেন্ডে", 2_500, "০১২৩৪৫৬৭৮৯"))
    }
}
