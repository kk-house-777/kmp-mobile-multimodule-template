package kk.tuist.app.feature

class FeatureScreenTest {
    @Test
    fun testGetTitle() {
        val screen = FeatureScreen()
        assertEquals("Feature A Screen", screen.getTitle())
    }

    @Test
    fun testGetSampleData() {
        val screen = FeatureScreen()
        val data = screen.getSampleData()
        assertEquals("feature-a-001", data.id)
        assertEquals("Sample Feature A", data.name)
    }
}