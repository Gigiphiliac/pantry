plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.gigi.pantry"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.gigi.pantry"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "app"
    productFlavors {
        create("prod") {
            dimension = "app"
            applicationId = "com.gigi.pantry"
            resValue("string", "app_name", "pantry")
        }
        create("dev") {
            dimension = "app"
            applicationId = "com.gigi.pantry.dev"
            resValue("string", "app_name", "pantry-dev")
        }
    }

    signingConfigs {
        create("release") {
            // For local builds: place release-keystore.jks in project root.
            // CI injects via KEYSTORE_BASE64 secret (see .github/workflows/release.yml).
            storeFile = rootProject.file("../release-keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "pantry-release"
            keyAlias = System.getenv("KEY_ALIAS") ?: "pantry-release-key"
            keyPassword = System.getenv("KEY_PASSWORD") ?: "pantry-release"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            // Signed with the project-level release keystore.
            // CI injects the keystore + credentials via secrets.
            signingConfig = signingConfigs["release"]

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
