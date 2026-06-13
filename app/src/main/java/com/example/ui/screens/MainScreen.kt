package com.example.ui.screens

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.example.data.VakitRepository
import com.example.model.PrayerTimeItem
import com.example.sensor.QiblaManager
import com.example.ui.VakitUiState
import com.example.ui.VakitViewModel
import com.example.ui.components.CompassView
import com.example.ui.theme.GoldAccent
import com.example.ui.theme.GreenBorderDark
import com.google.android.gms.location.LocationServices
import com.example.receiver.VakitNotificationHelper
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@SuppressLint("UnusedMaterial3ScaffoldPaddingParameter")
@Composable
fun MainScreen(viewModel: VakitViewModel) {
    val context = LocalContext.current
    val repository = remember { VakitRepository(context) }
    var selectedTab by remember { mutableIntStateOf(0) } // 0 = Vakitler, 1 = Kıble

    val scope = rememberCoroutineScope()
    var showCityDialog by remember { mutableStateOf(false) }
    var manualCityInput by remember { mutableStateOf("") }

    val turkishDate = remember {
        try {
            val sdf = SimpleDateFormat("dd MMMM EEEE", Locale("tr"))
            sdf.format(Date())
        } catch (e: Exception) {
            "Bugün"
        }
    }

    val uiState by viewModel.uiState.collectAsState()
    val cityName by viewModel.cityName.collectAsState()
    val countDownStr by viewModel.countdownStr.collectAsState()
    val nextPrayerName by viewModel.nextPrayerName.collectAsState()
    val nextPrayerTime by viewModel.nextPrayerTime.collectAsState()
    val isOffline by viewModel.isOffline.collectAsState()

    // 1. Compass Sensor Handling via DisposableEffect
    val qiblaManager = remember { QiblaManager(context) }
    val azimuth by qiblaManager.compassAzimuth.collectAsState()
    val sensorAccuracyLow by qiblaManager.sensorAccuracyLow.collectAsState()

    val userLat = repository.getSavedLatitude()
    val userLon = repository.getSavedLongitude()
    val qiblaBearing = remember(userLat, userLon) {
        qiblaManager.calculateQiblaBearing(userLat, userLon)
    }

    DisposableEffect(selectedTab) {
        if (selectedTab == 1) {
            qiblaManager.startListening()
        } else {
            qiblaManager.stopListening()
        }
        onDispose {
            qiblaManager.stopListening()
        }
    }

    // 2. Location Permission Handlers
    val locationLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val fineGranted = permissions[Manifest.permission.ACCESS_FINE_LOCATION] ?: false
        val coarseGranted = permissions[Manifest.permission.ACCESS_COARSE_LOCATION] ?: false
        
        if (fineGranted || coarseGranted) {
            // Get last known location and fetch timings
            try {
                val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)
                fusedLocationClient.lastLocation.addOnSuccessListener { location ->
                    if (location != null) {
                        viewModel.fetchTimingsByGps(location.latitude, location.longitude)
                    } else {
                        // fallback to saved
                        viewModel.fetchTimingsByGps(repository.getSavedLatitude(), repository.getSavedLongitude())
                    }
                }
            } catch (e: SecurityException) {
                Log.e("MainScreen", "Security exception requesting GPS", e)
            }
        } else {
            // Permission denied -> Show dialog fallback
            Toast.makeText(context, "Konum izni reddedildi. Şehir bilgisini manuel arayabilirsiniz.", Toast.LENGTH_LONG).show()
            showCityDialog = true
        }
    }

    // 3. Notification Permission Handlers (Android 13+)
    val notificationLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            VakitNotificationHelper.scheduleNextAlarm(context)
        } else {
            Toast.makeText(context, "Bildirim izni verilmedi. Ezan vakti uyarıları gösterilemeyebilir.", Toast.LENGTH_SHORT).show()
        }
    }

    // Trigger permission checks on first launcher render
    LaunchedEffect(Unit) {
        // Schedule permissions requesting sequentially
        val hasFine = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val hasCoarse = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        
        if (!hasFine && !hasCoarse) {
            locationLauncher.launch(
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                )
            )
        } else {
            // Refresh coordinates if we already have permissions
            try {
                val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)
                fusedLocationClient.lastLocation.addOnSuccessListener { location ->
                    if (location != null) {
                        viewModel.fetchTimingsByGps(location.latitude, location.longitude)
                    } else {
                        viewModel.fetchTimingsByGps(repository.getSavedLatitude(), repository.getSavedLongitude())
                    }
                }
            } catch (e: SecurityException) {
                viewModel.fetchTimingsByGps(repository.getSavedLatitude(), repository.getSavedLongitude())
            }
        }

        // Post Notification permission for Android 13+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val hasNotif = ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
            if (!hasNotif) {
                notificationLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
    }

    Scaffold(
        modifier = Modifier
            .fillMaxSize()
            .windowInsetsPadding(WindowInsets.safeDrawing),
        bottomBar = {
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surface,
                tonalElevation = 0.dp,
                modifier = Modifier
                    .drawBehind {
                        // Clean, precise border top to frame the navigation tray
                        drawLine(
                            color = GreenBorderDark.copy(alpha = 0.4f),
                            start = androidx.compose.ui.geometry.Offset(0f, 0f),
                            end = androidx.compose.ui.geometry.Offset(size.width, 0f),
                            strokeWidth = 1.dp.toPx()
                        )
                    }
                    .testTag("bottom_nav_bar")
            ) {
                NavigationBarItem(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    icon = { Icon(Icons.Default.AccessTime, contentDescription = "Vakitler") },
                    label = { Text("Vakitler", fontWeight = FontWeight.SemiBold) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = MaterialTheme.colorScheme.primary,
                        selectedTextColor = MaterialTheme.colorScheme.primary,
                        unselectedIconColor = MaterialTheme.colorScheme.secondary,
                        unselectedTextColor = MaterialTheme.colorScheme.secondary,
                        indicatorColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.15f)
                    ),
                    modifier = Modifier.testTag("nav_vakitler")
                )
                NavigationBarItem(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    icon = { Icon(Icons.Default.Explore, contentDescription = "Kıble") },
                    label = { Text("Kıble", fontWeight = FontWeight.SemiBold) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = MaterialTheme.colorScheme.primary,
                        selectedTextColor = MaterialTheme.colorScheme.primary,
                        unselectedIconColor = MaterialTheme.colorScheme.secondary,
                        unselectedTextColor = MaterialTheme.colorScheme.secondary,
                        indicatorColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.15f)
                    ),
                    modifier = Modifier.testTag("nav_kible")
                )
            }
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .background(MaterialTheme.colorScheme.background)
        ) {
            Column(modifier = Modifier.fillMaxSize()) {
                
                // Active warning banner if offline
                AnimatedVisibility(visible = isOffline) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Color(0xFFE67E22))
                            .padding(vertical = 10.dp, horizontal = 16.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.CloudOff, contentDescription = "Offline Mode", tint = Color.White)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "İnternet bağlantısı yok. Son çevrimdışı veriler gösteriliyor.",
                                color = Color.White,
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                }

                // Header view showing resolved location city name
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 24.dp, vertical = 20.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Bottom
                ) {
                    Column {
                        Text(
                            text = cityName.lowercase().replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() },
                            style = MaterialTheme.typography.headlineMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.primary,
                            letterSpacing = (-0.5).sp
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = "$turkishDate, Hicri Vakitler",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.secondary,
                            fontWeight = FontWeight.Normal
                        )
                    }

                    // Şehir Değiştir trigger button which doubles as location requester or manual modifier
                    IconButton(
                        onClick = {
                            manualCityInput = cityName
                            showCityDialog = true
                        },
                        modifier = Modifier
                            .size(42.dp)
                            .clip(RoundedCornerShape(21.dp))
                            .background(MaterialTheme.colorScheme.surface)
                            .border(
                                width = 1.dp,
                                color = MaterialTheme.colorScheme.outline.copy(alpha = 0.8f),
                                shape = RoundedCornerShape(21.dp)
                            )
                            .testTag("change_city_button")
                    ) {
                        Icon(
                            imageVector = Icons.Default.EditLocationAlt,
                            contentDescription = "Şehir Değiştir",
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }

                Divider(
                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                    thickness = 1.dp,
                    modifier = Modifier.padding(horizontal = 16.dp)
                )

                // Tab Routing Content
                if (selectedTab == 0) {
                    // TAB 0: VAKTİLER
                    when (val state = uiState) {
                        is VakitUiState.Loading -> {
                            Box(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .weight(1f),
                                contentAlignment = Alignment.Center
                            ) {
                                CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
                            }
                        }
                        is VakitUiState.Success -> {
                            PrayerTimesDashboard(
                                items = state.items,
                                nextName = nextPrayerName,
                                nextTime = nextPrayerTime,
                                countdown = countDownStr,
                                onRefreshCoordinates = {
                                    locationLauncher.launch(
                                        arrayOf(
                                            Manifest.permission.ACCESS_FINE_LOCATION,
                                            Manifest.permission.ACCESS_COARSE_LOCATION
                                        )
                                    )
                                }
                            )
                        }
                        is VakitUiState.Error -> {
                            Box(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .weight(1f)
                                    .padding(24.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Icon(
                                        imageVector = Icons.Default.Error,
                                        contentDescription = "Hata",
                                        tint = MaterialTheme.colorScheme.error,
                                        modifier = Modifier.size(56.dp)
                                    )
                                    Spacer(modifier = Modifier.height(16.dp))
                                    Text(
                                        text = state.message,
                                        style = MaterialTheme.typography.bodyLarge,
                                        textAlign = TextAlign.Center,
                                        color = MaterialTheme.colorScheme.error
                                    )
                                    Spacer(modifier = Modifier.height(24.dp))
                                    Button(
                                        onClick = { showCityDialog = true },
                                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                                    ) {
                                        Text("Bir Şehir Seç")
                                    }
                                }
                            }
                        }
                        is VakitUiState.Idle -> {
                            Box(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .weight(1f),
                                contentAlignment = Alignment.Center
                            ) {
                                Button(onClick = { showCityDialog = true }) {
                                    Text("Şehir Seçerek Başlayın")
                                }
                            }
                        }
                    }
                } else {
                    // TAB 1: KIBLE PUSULASI
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .weight(1f)
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Text(
                            text = "KIBLE YÖNÜ",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary,
                            letterSpacing = 2.sp
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Kırmızı ibreyi Kuzey'e (K) eşitlediğinizde Altın hilal ve minare Kıble açısını (Mekke / Kabe) gösterecektir.",
                            style = MaterialTheme.typography.bodySmall,
                            textAlign = TextAlign.Center,
                            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f),
                            modifier = Modifier.padding(horizontal = 16.dp)
                        )
                        Spacer(modifier = Modifier.height(24.dp))

                        CompassView(
                            azimuth = azimuth,
                            qiblaBearing = qiblaBearing,
                            sensorAccuracyLow = sensorAccuracyLow,
                            modifier = Modifier.weight(1f)
                        )
                        
                        // Subtle warning that magnetic accessories such as phone mounts/magnetic cases affect compass accuracy
                        Text(
                            text = "Not: Çevredeki metal kılıf, mıknatıs veya elektrik hatları pusulanın sapmasına yol açabilir.",
                            style = MaterialTheme.typography.labelSmall,
                            textAlign = TextAlign.Center,
                            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.4f),
                            modifier = Modifier.padding(top = 10.dp)
                        )
                    }
                }
            }

            // Fallback manual city editor dialog
            if (showCityDialog) {
                AlertDialog(
                    onDismissRequest = { showCityDialog = false },
                    title = { Text("Şehir Seçin / Değiştirin") },
                    text = {
                        Column {
                            Text(
                                "Lütfen vakitlerini görmek istediğiniz Türk şehrini yazın (Örn: Istanbul, Ankara, Izmir, Konya):",
                                style = MaterialTheme.typography.bodyMedium,
                                modifier = Modifier.padding(bottom = 8.dp)
                            )
                            OutlinedTextField(
                                value = manualCityInput,
                                onValueChange = { manualCityInput = it },
                                placeholder = { Text("Şehir İsmi Örn: Ankara") },
                                singleLine = true,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .testTag("city_text_field")
                            )
                        }
                    },
                    confirmButton = {
                        Button(
                            onClick = {
                                if (manualCityInput.isNotBlank()) {
                                    viewModel.fetchTimingsByCityName(manualCityInput.trim())
                                    showCityDialog = false
                                }
                            },
                            modifier = Modifier.testTag("submit_city_button")
                        ) {
                            Text("Ara ve Uygula")
                        }
                    },
                    dismissButton = {
                        TextButton(onClick = { showCityDialog = false }) {
                            Text("Vazgeç")
                        }
                    }
                )
            }
        }
    }
}

@Composable
fun PrayerTimesDashboard(
    items: List<PrayerTimeItem>,
    nextName: String,
    nextTime: String,
    countdown: String,
    onRefreshCoordinates: () -> Unit
) {
    val infiniteTransition = rememberInfiniteTransition(label = "bead_pulse")
    val beadAlpha by infiniteTransition.animateFloat(
        initialValue = 0.3f,
        targetValue = 1.0f,
        animationSpec = infiniteRepeatable(
            animation = tween(1200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "bead_alpha"
    )

    // Robust parser to extract digital hours-minutes & seconds from ViewModel ticker text
    val timeParts = remember(countdown) {
        var hours = 0
        var minutes = 0
        var seconds = 0
        var useClockFormat = false
        try {
            val hMatch = java.util.regex.Pattern.compile("(\\d+)\\s*saat").matcher(countdown)
            if (hMatch.find()) {
                hours = hMatch.group(1).toInt()
                useClockFormat = true
            }
            val mMatch = java.util.regex.Pattern.compile("(\\d+)\\s*dk").matcher(countdown)
            if (mMatch.find()) {
                minutes = mMatch.group(1).toInt()
                useClockFormat = true
            }
            val sMatch = java.util.regex.Pattern.compile("(\\d+)\\s*sn").matcher(countdown)
            if (sMatch.find()) {
                seconds = sMatch.group(1).toInt()
                useClockFormat = true
            }
        } catch (e: Exception) {
            useClockFormat = false
        }
        if (useClockFormat) Triple(hours, minutes, seconds) else null
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .testTag("prayer_dashboard_list"),
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // High fidelity Countdown Hero Card with Glass background and glowing ambient light
        item {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(32.dp))
                    .background(
                        Brush.linearGradient(
                            colors = listOf(Color(0xFF2E352E), Color(0xFF1D201C))
                        )
                    )
                    .border(
                        1.2.dp,
                        MaterialTheme.colorScheme.outline.copy(alpha = 0.5f),
                        RoundedCornerShape(32.dp)
                    )
                    .drawBehind {
                        // Absorb glowing ambient mint shape in the top right corner
                        drawCircle(
                            color = Color(0xFFD1E8D1).copy(alpha = 0.12f),
                            radius = size.width * 0.45f,
                            center = androidx.compose.ui.geometry.Offset(size.width, 0f)
                        )
                    }
                    .testTag("countdown_hero_card")
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "SIRADAKİ VAKİT",
                        style = MaterialTheme.typography.labelMedium,
                        letterSpacing = 2.sp,
                        color = Color(0xFFA5D6A7),
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = nextName,
                        style = MaterialTheme.typography.headlineLarge,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        fontSize = 32.sp
                    )
                    Spacer(modifier = Modifier.height(18.dp))
                    
                    // Countdown ticker parsed into dynamic high density typography
                    if (timeParts != null) {
                        Row(
                            verticalAlignment = Alignment.Bottom,
                            horizontalArrangement = Arrangement.Center
                        ) {
                            Text(
                                text = String.format(Locale.US, "%02d:%02d", timeParts.first, timeParts.second),
                                style = MaterialTheme.typography.displayLarge,
                                color = Color.White,
                                fontWeight = FontWeight.Light,
                                fontSize = 52.sp,
                                letterSpacing = (-2).sp,
                                modifier = Modifier.alignByBaseline()
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = String.format(Locale.US, "%02d", timeParts.third),
                                style = MaterialTheme.typography.titleLarge,
                                color = Color.White.copy(alpha = 0.6f),
                                fontWeight = FontWeight.Normal,
                                fontSize = 20.sp,
                                modifier = Modifier.alignByBaseline()
                            )
                        }
                    } else {
                        // Fallback state if countdown is descriptive/loading
                        Text(
                            text = countdown,
                            style = MaterialTheme.typography.headlineMedium,
                            color = Color(0xFFD1E8D1),
                            fontWeight = FontWeight.SemiBold,
                            textAlign = TextAlign.Center
                        )
                    }

                    // Pulsing Status dot and subline info helper
                    Row(
                        modifier = Modifier.padding(top = 16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .size(8.dp)
                                .graphicsLayer { alpha = beadAlpha }
                                .clip(RoundedCornerShape(4.dp))
                                .background(Color(0xFFD1E8D1))
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "$nextName vakti girişi için kalan süre",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color(0xFF90928E)
                        )
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                    Row(
                        modifier = Modifier
                            .clickable { onRefreshCoordinates() }
                            .padding(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.MyLocation,
                            contentDescription = "Refresh GPS",
                            tint = Color(0xFFD1E8D1),
                            modifier = Modifier.size(14.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = "Konumumu Güncelle",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color(0xFFD1E8D1),
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }
        }

        // Section Title
        item {
            Text(
                text = "Bugünün Vakitleri",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary,
                letterSpacing = 0.5.sp,
                modifier = Modifier.padding(top = 8.dp)
            )
        }

        // List container of items with Frosted Glass styling
        item {
            Surface(
                color = MaterialTheme.colorScheme.surface.copy(alpha = 0.4f),
                shape = RoundedCornerShape(32.dp),
                border = BorderStroke(
                    1.dp,
                    MaterialTheme.colorScheme.outline.copy(alpha = 0.3f)
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(8.dp)) {
                    items.forEach { item ->
                        val isNext = item.name == nextName
                        
                        val rowBg = if (isNext) {
                            MaterialTheme.colorScheme.primary
                        } else {
                            Color.Transparent
                        }

                        val rowColor = if (isNext) {
                            MaterialTheme.colorScheme.onPrimary
                        } else {
                            MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f)
                        }

                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp)
                                .clip(RoundedCornerShape(20.dp))
                                .background(rowBg)
                                .padding(horizontal = 20.dp, vertical = 14.dp)
                                .testTag("prayer_item_${item.id.lowercase()}"),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    imageVector = getPrayerIcon(item.id),
                                    contentDescription = item.name,
                                    tint = if (isNext) rowColor else MaterialTheme.colorScheme.secondary,
                                    modifier = Modifier.size(20.dp)
                                )
                                Spacer(modifier = Modifier.width(16.dp))
                                Text(
                                    text = item.name,
                                    style = MaterialTheme.typography.bodyLarge,
                                    fontWeight = if (isNext) FontWeight.Bold else FontWeight.Medium,
                                    color = rowColor
                                )

                                if (isNext) {
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Surface(
                                        color = rowColor.copy(alpha = 0.15f),
                                        shape = RoundedCornerShape(4.dp)
                                    ) {
                                        Text(
                                            text = "ŞİMDİ",
                                            fontSize = 9.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = rowColor,
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                        )
                                    }
                                }
                            }

                            Text(
                                text = item.time,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = if (isNext) FontWeight.Bold else FontWeight.Normal,
                                color = rowColor
                            )
                        }
                    }
                }
            }
        }
    }
}

// Icon mapper helper
private fun getPrayerIcon(id: String): ImageVector {
    return when (id) {
        "FAJR" -> Icons.Default.Brightness3 // Crescent shape
        "SUNRISE" -> Icons.Default.WbTwilight
        "DHUHR" -> Icons.Default.WbSunny
        "ASR" -> Icons.Default.WbSunny // Afternoon sun
        "MAGHRIB" -> Icons.Default.NightsStay
        "ISHA" -> Icons.Default.NightsStay // Dark night sky
        else -> Icons.Default.AccessTime
    }
}
