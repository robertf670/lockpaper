import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read key.properties file
// Try resolving relative to the parent project (the 'android' directory)
// Use non-null assertion (!!) as parent should always exist here
val keyPropertiesFile = parent!!.file("key.properties")
// Debug: Print the resolved path and existence check - REMOVED
// println("key.properties Path: ${keyPropertiesFile.absolutePath}")
// println("key.properties Exists?: ${keyPropertiesFile.exists()}")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "ie.qqrxi.lockpaper.lockpaper"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ie.qqrxi.lockpaper.lockpaper"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        
        // IMPORTANT: When updating app version for release:
        // 1. Increment versionCode by 1 for each new release
        // 2. Update versionName to match the semantic version (also update in pubspec.yaml)
        // 3. Update currentAppVersion in lib/core/services/version_service.dart
        // 4. Add new release info to versionHistory list in the version_service.dart file
        versionCode = 3
        versionName = "1.1.0"
    }

    // Define signing configuration for release
    signingConfigs {
        create("release") {
            // Debugging: Print the values read from key.properties - REMOVED
            // println("Signing Info: storeFile Path = ${keyProperties["storeFile"]}")
            // println("Signing Info: keyAlias = ${keyProperties["keyAlias"]}")
            // println("Signing Info: storePassword Present = ${keyProperties["storePassword"] != null}") 
            // println("Signing Info: keyPassword Present = ${keyProperties["keyPassword"] != null}") 

            keyAlias = keyProperties["keyAlias"] as String?
            keyPassword = keyProperties["keyPassword"] as String?
            storeFile = keyProperties["storeFile"]?.let { rootProject.file(it) } // Use let for safe file path handling
            storePassword = keyProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Use the release signing config defined above.
            signingConfig = signingConfigs.getByName("release")
            // Add other release-specific settings if needed (e.g., ProGuard)
            // minifyEnabled = true
            // shrinkResources = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
