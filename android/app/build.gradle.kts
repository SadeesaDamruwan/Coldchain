plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services plugin for Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.coldchain"
    compileSdk = flutter.compileSdkVersion

    // Stops the 25.0.2 build tools error
    buildToolsVersion = "34.0.0"

    ndkVersion = flutter.ndkVersion

    compileOptions {
        // --- 1. ENABLE DESUGARING ---
        // This allows Java 8 features used by notifications to work on older Androids
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.coldchain"

        // --- 2. SET MIN SDK TO 23 ---
        // Required for Firebase Messaging and Geolocator
        minSdk = flutter.minSdkVersion

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // --- 3. ADD DESUGARING LIBRARY ---
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))

    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-messaging")
}
