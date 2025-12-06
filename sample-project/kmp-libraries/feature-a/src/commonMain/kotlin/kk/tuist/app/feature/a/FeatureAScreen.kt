package kk.tuist.app.feature.a

class FeatureAScreen {
    fun getTitle(): String = "Feature A Screen"

    fun getContent(): String = "This is Feature A module content"

    fun getSampleData(): FeatureAData {
        return FeatureAData(
            id = "feature-a-001",
            name = "Sample Feature A",
            description = "This is a sample data from Feature A module"
        )
    }
}

data class FeatureAData(
    val id: String,
    val name: String,
    val description: String
)
