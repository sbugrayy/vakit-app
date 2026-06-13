package com.example.api

import com.example.model.AladhanResponse
import retrofit2.http.GET
import retrofit2.http.Query

interface AladhanService {
    @GET("v1/timings")
    suspend fun getTimings(
        @Query("latitude") latitude: Double,
        @Query("longitude") longitude: Double,
        @Query("method") method: Int = 13
    ): AladhanResponse

    @GET("v1/timingsByCity")
    suspend fun getTimingsByCity(
        @Query("city") city: String,
        @Query("country") country: String = "Turkey",
        @Query("method") method: Int = 13
    ): AladhanResponse
}
