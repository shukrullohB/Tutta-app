import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keyPropertiesFile.exists()
if (hasReleaseSigning) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

fun signingProp(name: String): String {
    return keyProperties.getProperty(name)
        ?: error("Missing '$name' in android/key.properties")
}

android {
    namespace = "uz.tutta.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = (localProperties.getProperty("TUTTA_APPLICATION_ID") ?: "uz.tutta.app")
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = signingProp("keyAlias")
                keyPassword = signingProp("keyPassword")
                storeFile = file(signingProp("storeFile"))
                storePassword = signingProp("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
