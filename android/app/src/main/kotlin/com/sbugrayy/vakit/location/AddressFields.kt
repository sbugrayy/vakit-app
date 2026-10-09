package com.sbugrayy.vakit.location

data class AddressFields(
    val adminArea: String?,
    val subAdminArea: String?,
    val locality: String?,
    val subLocality: String?
) {
    fun toPlace(): Pair<String?, String?> {
        val province = clean(adminArea)
        val district = clean(subAdminArea)
            ?: clean(locality)
            ?: clean(subLocality)
        return Pair(province, district)
    }

    private fun clean(value: String?): String? {
        return value?.trim()?.takeIf { it.isNotEmpty() }
    }
}
