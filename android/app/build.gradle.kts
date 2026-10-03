plugins {
    id("com.android.application")
    // AGP 8.12'de Kotlin yerleşik değil; eklenti açıkça uygulanıyor
    // (bkz. android/settings.gradle.kts'teki sürüm notu).
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sbugrayy.vakit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.sbugrayy.vakit"
        // 26: bildirim kanalları (API 26) ve RemoteViews içindeki geri sayan
        // Chronometer (API 24) kalıcı bildirimin temeli; altını desteklemiyoruz.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // NotificationCompat ve RemoteViews yardımcıları (kalıcı bildirim motoru).
    // Flutter embedding zaten 1.13.1'i getiriyor; açıkça yazmak sürümün
    // kaymasını önlüyor. Sürüm makinenin önbelleğinde (indirme yok).
    implementation("androidx.core:core:1.13.1")

    // Bildirim motorunun saf Kotlin mantığı için JVM testleri
    // (./gradlew :app:testDebugUnitTest). org.json Android'de platformun
    // parçası, JVM testlerinde ise yok; gerçek uygulaması gerekiyor. İki
    // sürüm de önbellekte.
    testImplementation("junit:junit:4.12")
    testImplementation("org.json:json:20180813")
}

flutter {
    source = "../.."
}
