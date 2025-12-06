package kk.tuist.app.data.a

class DataARepository {
    fun fetchData(): List<DataAModel> {
        return listOf(
            DataAModel(
                id = "data-a-001",
                title = "Data A Item 1",
                value = 100
            ),
            DataAModel(
                id = "data-a-002",
                title = "Data A Item 2",
                value = 200
            ),
            DataAModel(
                id = "data-a-003",
                title = "Data A Item 3",
                value = 300
            )
        )
    }

    fun getById(id: String): DataAModel? {
        return fetchData().find { it.id == id }
    }
}

data class DataAModel(
    val id: String,
    val title: String,
    val value: Int
)
