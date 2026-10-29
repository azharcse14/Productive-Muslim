package com.productivemuslim.app

import org.junit.Assert.assertEquals
import org.junit.Test

/** Thresholds as in ShakeCounter: ≥ 2.7 g, ≥ 250 ms apart, 5 within 3 s. */
class ShakeCounterTest {
    private var fired = 0
    private val counter = ShakeCounter(5) { fired++ }

    private fun shake(vararg atMs: Long, g: Float = 3f) = atMs.forEach { counter.sample(g, it) }

    @Test
    fun fiveHardShakesWithinThreeSecondsFireOnce() {
        shake(0, 250, 500, 750, 1000)
        assertEquals(1, fired)
    }

    @Test
    fun justBelowThresholdIsIgnored() {
        shake(0, 250, 500, 750, 1000, g = 2.69f)
        assertEquals(0, fired)
        shake(0, 250, 500, 750, 1000, g = 2.7f)
        assertEquals(1, fired)
    }

    @Test
    fun samplesUnder250MsApartCountOnce() {
        // One shake spans several sensor samples: 0..240 is a single shake.
        shake(0, 100, 240, 250, 500, 750)
        assertEquals(0, fired)
        shake(1000)
        assertEquals(1, fired)
    }

    @Test
    fun fifthShakeOutsideTheWindowDoesNotFire() {
        shake(0, 1000, 2000, 2500, 3001)
        assertEquals(0, fired)
        // 1000..3001 are still in the window: one more fires.
        shake(3500)
        assertEquals(1, fired)
    }

    @Test
    fun resetsAfterFiring() {
        shake(0, 250, 500, 750, 1000)
        shake(1250, 1500, 1750, 2000)
        assertEquals(1, fired)
        shake(2250)
        assertEquals(2, fired)
    }

    @Test
    fun resetClearsCountedShakes() {
        shake(0, 250, 500, 750)
        counter.reset()
        shake(1000)
        assertEquals(0, fired)
    }
}
