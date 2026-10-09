package com.sbugrayy.vakit.location

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class AddressFieldsTest {

    @Test
    fun adminAreaAndSubAdminAreaMapToProvinceAndDistrict() {
        val fields = AddressFields(
            adminArea = "İstanbul",
            subAdminArea = "Kadıköy",
            locality = null,
            subLocality = null
        )
        val (province, district) = fields.toPlace()

        assertEquals("İstanbul", province)
        assertEquals("Kadıköy", district)
    }

    @Test
    fun emptySubAdminAreaFallsBackToLocality() {
        val fields = AddressFields(
            adminArea = "Ankara",
            subAdminArea = "",
            locality = "Çankaya",
            subLocality = null
        )
        val (province, district) = fields.toPlace()

        assertEquals("Ankara", province)
        assertEquals("Çankaya", district)
    }

    @Test
    fun whitespaceSubAdminAreaFallsBackToLocality() {
        val fields = AddressFields(
            adminArea = "Ankara",
            subAdminArea = "   ",
            locality = "Çankaya",
            subLocality = null
        )
        val (province, district) = fields.toPlace()

        assertEquals("Ankara", province)
        assertEquals("Çankaya", district)
    }

    @Test
    fun fallsBackToSubLocalityWhenOthersEmpty() {
        val fields = AddressFields(
            adminArea = "İzmir",
            subAdminArea = null,
            locality = "  ",
            subLocality = "Bornova"
        )
        val (province, district) = fields.toPlace()

        assertEquals("İzmir", province)
        assertEquals("Bornova", district)
    }

    @Test
    fun allWhitespaceReturnsNulls() {
        val fields = AddressFields(
            adminArea = "   ",
            subAdminArea = " ",
            locality = "\t",
            subLocality = "\n"
        )
        val (province, district) = fields.toPlace()

        assertNull(province)
        assertNull(district)
    }

    @Test
    fun allNullsReturnsNulls() {
        val fields = AddressFields(
            adminArea = null,
            subAdminArea = null,
            locality = null,
            subLocality = null
        )
        val (province, district) = fields.toPlace()

        assertNull(province)
        assertNull(district)
    }

    @Test
    fun turkishCharactersPreserved() {
        val fields = AddressFields(
            adminArea = "Ağrı",
            subAdminArea = "Doğubayazıt",
            locality = "Şahinbey",
            subLocality = null
        )
        val (province, district) = fields.toPlace()

        assertEquals("Ağrı", province)
        assertEquals("Doğubayazıt", district)
    }

    @Test
    fun valuesAreTrimmed() {
        val fields = AddressFields(
            adminArea = "  Eskişehir  ",
            subAdminArea = "  Tepebaşı  ",
            locality = null,
            subLocality = null
        )
        val (province, district) = fields.toPlace()

        assertEquals("Eskişehir", province)
        assertEquals("Tepebaşı", district)
    }
}
