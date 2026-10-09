pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// Sürümler bilinçli olarak makinenin önbelleğinden seçildi: AGP 8.12.0 ve
// Gradle 9.0.0 finans-app ile aynı, Kotlin 2.2.20 (Flutter 3.44.6, 2.2.10
// için "destek yakında kalkacak" uyarısı veriyor; 2.2.20 de önbellekte).
// Flutter şablonu AGP 9.0.1 + Gradle 9.1.0 getiriyor, ama bu makinede
// internet yavaş ve Norton taramalı (Gradle dağıtımı ~3,4 MB/dk indi). Bu
// birleşim indirme gerektirmeden APK üretiyor (2026-10-03, ~3 dk). AGP 9'a
// geçiş internet uygun olduğunda ayrı bir iş (bkz. IMPLEMENTATION_PLAN.md).
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.12.0" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
