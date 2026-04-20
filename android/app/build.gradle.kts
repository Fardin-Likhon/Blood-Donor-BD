plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    // 1. Updated to match your google-services.json exactly
    namespace = "com.example.flutter_application_1"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        // 2. Updated to match your google-services.json exactly
        applicationId = "com.example.flutter_application_1"
        
        // 3. Recommended for modern Firebase features
        minSdk = flutter.minSdkVersion 
        targetSdk = flutter.targetSdkVersion
        
        versionCode = project.findProperty("flutterVersionCode")?.toString()?.toInt() ?: 1
        versionName = project.findProperty("flutterVersionName")?.toString() ?: "1.0"
    }

    // Fixed JVM Target Compatibility for MacBook M3
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
