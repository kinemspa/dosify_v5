plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream
import java.util.Properties

android {
    namespace = "com.dosifi.dosifi_v5"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Application ID used by Play Store / device install identification.
        applicationId = "com.dosifi.app"
        // SDK targets for Android.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")

            if (!keystorePropertiesFile.exists()) {
                throw GradleException(
                    "Missing android/key.properties for release signing. " +
                        "Create it from android/key.properties.example and provide an upload keystore for Play App Signing.",
                )
            }

            val keystoreProperties = Properties()
            FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }

            storeFile = rootProject.file(
                requireNotNull(keystoreProperties.getProperty("storeFile")) {
                    "key.properties missing storeFile"
                },
            )
            storePassword = requireNotNull(keystoreProperties.getProperty("storePassword")) {
                "key.properties missing storePassword"
            }
            keyAlias = requireNotNull(keystoreProperties.getProperty("keyAlias")) {
                "key.properties missing keyAlias"
            }
            keyPassword = requireNotNull(keystoreProperties.getProperty("keyPassword")) {
                "key.properties missing keyPassword"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
