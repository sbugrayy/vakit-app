package com.example.ui

import android.app.Application
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.data.VakitRepository
import com.example.model.AladhanTimings
import com.example.model.PrayerTimeItem
import com.example.receiver.VakitNotificationHelper
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.Calendar

sealed interface VakitUiState {
    object Idle : VakitUiState
    object Loading : VakitUiState
    data class Success(val timings: AladhanTimings, val items: List<PrayerTimeItem>) : VakitUiState
    data class Error(val message: String) : VakitUiState
}

class VakitViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = VakitRepository(application)

    private val _uiState = MutableStateFlow<VakitUiState>(VakitUiState.Idle)
    val uiState: StateFlow<VakitUiState> = _uiState.asStateFlow()

    private val _cityName = MutableStateFlow(repository.getSavedCityName())
    val cityName: StateFlow<String> = _cityName.asStateFlow()

    private val _countdownStr = MutableStateFlow("Yükleniyor...")
    val countdownStr: StateFlow<String> = _countdownStr.asStateFlow()

    private val _nextPrayerName = MutableStateFlow("")
    val nextPrayerName: StateFlow<String> = _nextPrayerName.asStateFlow()

    private val _nextPrayerTime = MutableStateFlow("")
    val nextPrayerTime: StateFlow<String> = _nextPrayerTime.asStateFlow()

    val isOffline: StateFlow<Boolean> = repository.isOffline

    private var countdownJob: Job? = null

    init {
        // Prepare initial offline timings cache lookup so the app starts instantly if coordinates exist
        loadInitialData()
    }

    private fun loadInitialData() {
        val cached = repository.getCachedTimings()
        val savedCity = repository.getSavedCityName()
        _cityName.value = savedCity
        
        if (cached != null) {
            val items = repository.mapToListOfItems(cached)
            _uiState.value = VakitUiState.Success(cached, items)
            startTicker(cached)
            // Gently sync notifications schedule
            VakitNotificationHelper.scheduleNextAlarm(getApplication())
        }
    }

    /**
     * Fetch with user GPS coordinates.
     */
    fun fetchTimingsByGps(lat: Double, lon: Double) {
        viewModelScope.launch {
            _uiState.value = VakitUiState.Loading
            val timings = repository.fetchTimingsFromGps(lat, lon)
            if (timings != null) {
                val items = repository.mapToListOfItems(timings)
                _uiState.value = VakitUiState.Success(timings, items)
                _cityName.value = repository.getSavedCityName()
                startTicker(timings)
                
                // Set the status bar ongoing drawer and calendar wakeup alarms
                VakitNotificationHelper.scheduleNextAlarm(getApplication())
            } else {
                _uiState.value = VakitUiState.Error("Namaz vakitleri alınamadı. Lütfen internet bağlantınızı kontrol edin.")
            }
        }
    }

    /**
     * Fallback fetch via explicit text input.
     */
    fun fetchTimingsByCityName(city: String) {
        if (city.isBlank()) return
        
        viewModelScope.launch {
            _uiState.value = VakitUiState.Loading
            val timings = repository.fetchTimingsByCityName(city)
            if (timings != null) {
                val items = repository.mapToListOfItems(timings)
                _uiState.value = VakitUiState.Success(timings, items)
                _cityName.value = repository.getSavedCityName()
                startTicker(timings)

                // Reschedule notifications
                VakitNotificationHelper.scheduleNextAlarm(getApplication())
            } else {
                _uiState.value = VakitUiState.Error("'$city' için veriler sunucudan alınamadı. Şehir ismini kontrol edip tekrar deneyin.")
            }
        }
    }

    /**
     * Ticker job loop that executes on UI coroutine scope, recalculates remaining mills
     * every second, and updates the display values.
     */
    private fun startTicker(timings: AladhanTimings) {
        countdownJob?.cancel()
        countdownJob = viewModelScope.launch {
            while (true) {
                val nextInfo = repository.getNextPrayerInfo(timings)
                _nextPrayerName.value = nextInfo.name
                _nextPrayerTime.value = nextInfo.time

                val diffMillis = nextInfo.calendar.timeInMillis - System.currentTimeMillis()
                if (diffMillis > 0) {
                    _countdownStr.value = formatDiff(diffMillis)
                } else {
                    _countdownStr.value = "Karşılanıyor..."
                }
                delay(1000L)
            }
        }
    }

    private fun formatDiff(diffMillis: Long): String {
        val seconds = (diffMillis / 1000) % 60
        val minutes = (diffMillis / (1000 * 60)) % 60
        val hours = (diffMillis / (1000 * 60 * 60))
        
        val hoursPart = if (hours > 0) "${hours} saat " else ""
        val minutesPart = if (minutes > 0 || hours > 0) "${minutes} dk " else ""
        return "${hoursPart}${minutesPart}${seconds} sn"
    }

    override fun onCleared() {
        super.onCleared()
        countdownJob?.cancel()
    }
}
