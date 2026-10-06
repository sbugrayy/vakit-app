import java.util.Properties

plugins {
    id("com.android.application")
    // AGP 8.12'de Kotlin yerleşik değil; eklenti açıkça uygulanıyor
    // (bkz. android/settings.gradle.kts'teki sürüm notu).
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Yayın imzası: anahtar deposu ve parolalar repoda değil, android/key.properties
// dosyasında (git dışı, bkz. android/.gitignore). Dosya yoksa (ör. başka bir
// makine ya da CI) yayın derlemesi debug anahtarıyla imzalanır; böylece
// `flutter run --release` yine çalışır ama o APK dağıtılmaz.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}
val hasReleaseKey = keystoreProperties.getProperty("storeFile") != null

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

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
