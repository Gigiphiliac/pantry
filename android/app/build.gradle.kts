plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.gigi.pantry"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    setProperty("archivesBaseName", "pantry")

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
        create("ci") {
            storeFile = file("${System.getProperty("user.home")}/.android/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            // Signed with the auto-generated debug keystore initially.
            // For production, replace with secrets-based signing:
            //   run signingConfig = signingConfigs.release
            signingConfig = signingConfigs["ci"]

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    applicationVariants.configureEach { variant ->
        variant.outputs.configureEach { output ->
            output.outputFileName = "pantry-v${variant.versionName}.apk"
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
