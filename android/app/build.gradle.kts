plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "avs.com.famradar"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "avs.com.famradar"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndkVersion = "29.0.13113456"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
//        release {
//            // TODO: Add your own signing config for the release build.
//            // Signing with the debug keys for now, so `flutter run --release` works.
//            signingConfig = signingConfigs.getByName("debug")
//        }
    }
}
dependencies {
//    implementation("com.google.android.gms:play-services-location:21.3.0")
//    implementation(platform("com.google.firebase:firebase-bom:33.13.0"))
//    implementation("com.google.firebase:firebase-analytics")
    implementation("io.getstream:stream-webrtc-android:1.3.8")
    {
        exclude(group = "com.mesibo.api", module = "webrtc")
    }
//    implementation("androidx.databinding:compiler:3.2.0-alpha11")
//    implementation("com.google.firebase:firebase-firestore-ktx:25.1.4")
    implementation("androidx.core:core-ktx:1.16.0")
    implementation("com.google.android.gms:play-services-location:21.3.0")
//    implementation("org.webrtc:webrtc:1.0.32006")
    implementation(platform("com.google.firebase:firebase-bom:33.13.0"))
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("io.flutter:flutter_embedding_debug:1.0.0-cf56914b326edb0ccb123ffdc60f00060bd513fa")

    // Enforce a consistent version of androidx.databinding
    implementation("androidx.databinding:databinding-common:8.10.0")
    implementation("androidx.databinding:databinding-runtime:8.10.0")
    implementation("androidx.databinding:databinding-adapters:8.10.0")

    // Exclude conflicting baseLibrary to avoid duplicates
    configurations.all {
        exclude(group = "androidx.databinding', module: 'baseLibrary")
    }
}

flutter {
    source = "../.."
}
