package kk.tuist.app.feature.a

import kotlin.test.Test
import kotlin.test.assertEquals

class FeatureAScreenTest {
    @Test
    fun testGetTitle() {
        val screen = FeatureAScreen()
        assertEquals("Feature A Screen", screen.getTitle())
    }

    @Test
    fun testGetSampleData() {
        val screen = FeatureAScreen()
        val data = screen.getSampleData()
        assertEquals("feature-a-001", data.id)
        assertEquals("Sample Feature A", data.name)
    }
}
