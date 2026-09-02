import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing material is read from `android/key.properties`, which is
// gitignored along with the keystore itself. Create it from
// `key.properties.example` before cutting a release build:
//
//     storeFile=/absolute/path/to/breathefree-release.jks
//     storePassword=...
//     keyAlias=breathefree
//     keyPassword=...
//
// When the file is absent the release build falls back to the debug keystore so
// `flutter run --release` still works locally. A debug-signed artifact is fine
// for local testing and is rejected by the Play Store, which is the intended
// behaviour — a missing keystore must not silently produce something that looks
// publishable. This mirrors the sibling Chronic Care app so both repositories
// fail the same way for the same reason.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseKeystore = keystorePropertiesFile.exists() &&
    keystoreProperties.getProperty("storeFile") != null

if (!hasReleaseKeystore) {
    println(
        "WARNING: android/key.properties not found - the release build will be signed with the " +
            "DEBUG keystore and CANNOT be uploaded to the Play Store. " +
            "See android/key.properties.example."
    )
}

android {
    namespace = "com.breathefree.breathefree_patient"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // The applicationId is permanent once the app is published: Play matches
        // updates on it, and it cannot be changed afterwards. This value is valid
        // and unique, but choosing the final one is still an open decision —
        // "Choose the final application ID" in PRODUCTION_RELEASE_CHECKLIST.md.
        // Settle it BEFORE the first upload; the sibling app uses the
        // com.tetherhealthgroup.* namespace, which this does not follow.
        applicationId = "com.breathefree.breathefree_patient"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
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
            signingConfig = if (hasReleaseKeystore) {
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

flutter {
    source = "../.."
}
