package kk.tuist.app.data.a

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class DataARepositoryTest {
    @Test
    fun testFetchData() {
        val repository = DataARepository()
        val data = repository.fetchData()
        assertEquals(3, data.size)
        assertEquals("data-a-001", data[0].id)
    }

    @Test
    fun testGetById() {
        val repository = DataARepository()
        val item = repository.getById("data-a-002")
        assertNotNull(item)
        assertEquals("Data A Item 2", item.title)
        assertEquals(200, item.value)
    }

    @Test
    fun testGetByIdNotFound() {
        val repository = DataARepository()
        val item = repository.getById("non-existent-id")
        assertNull(item)
    }
}
