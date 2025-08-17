import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.harshm.subtrackr"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true

    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.harshm.subtrackr"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 5
        versionName = "1.0.6"
        
        // Explicitly disable deferred components
        manifestPlaceholders["deferredComponentsEnabled"] = "false"
    }

    // Explicitly disable dynamic features and deferred components
    buildFeatures {
        buildConfig = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// Hard-block play:core to prevent it from being pulled in
configurations.all {
    resolutionStrategy.eachDependency {
        if (requested.group == "com.google.android.play" && requested.name == "core") {
            throw GradleException("play:core is forbidden. Migrate to app-update/review/asset-delivery.")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Only add what you actually need:
    // implementation("com.google.android.play:app-update:2.1.0") // if you need in-app updates
    // implementation("com.google.android.play:review:2.0.1")     // if you need in-app reviews
}


flutter {
    source = "../.."
}
