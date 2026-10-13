import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. Secrets come only from android/key.properties (gitignored)
// and are never echoed. Reading the file never fails the build by itself, so
// debug-only tasks work without it; the release guard below does the failing.
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties().apply {
    if (keyPropertiesFile.isFile) keyPropertiesFile.inputStream().use { load(it) }
}
val requiredSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val missingSigningKeys = requiredSigningKeys.filter {
    keyProperties.getProperty(it).isNullOrBlank()
}
val signingProblems = buildList {
    if (!keyPropertiesFile.isFile) {
        add("android/key.properties not found")
    } else {
        if (missingSigningKeys.isNotEmpty()) {
            add("android/key.properties is missing or has empty: ${missingSigningKeys.joinToString(", ")}")
        }
        val storePath = keyProperties.getProperty("storeFile")
        if (!storePath.isNullOrBlank() && !file(storePath.trim()).isFile) {
            add("storeFile does not point to an existing keystore file")
        }
    }
}
val releaseSigningReady = signingProblems.isEmpty()
// CI builds an intentionally unsigned bundle by setting this variable. It never
// selects the debug key: the artifact is simply left unsigned.
val allowUnsignedRelease = System.getenv("TETHER_ALLOW_UNSIGNED_RELEASE") == "1"

android {
    namespace = "com.breathefree.breathefree_patient"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
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
        if (releaseSigningReady) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile").trim())
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias").trim()
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Never falls back to the debug key. Without a complete
            // key.properties the guard below fails release builds.
            if (releaseSigningReady) {
                signingConfig = signingConfigs.getByName("release")
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

// Fail any build that schedules a release variant task (bundleRelease,
// signReleaseBundle, installRelease, flavored variants, ...) without a usable
// upload key. Checked once the task graph is known, so debug-only invocations
// (flutter run, assembleDebug, analyze) never trip it.
gradle.taskGraph.whenReady {
    // Any :app task of a release variant (bundleRelease, signReleaseBundle,
    // packageReleaseBundle, packageReleaseUniversalApk, installRelease,
    // flavored variants, ...). Debug and profile tasks never contain "Release".
    val buildsRelease = allTasks.any {
        it.project == project && it.name.contains("Release")
    }
    if (buildsRelease && !releaseSigningReady && !allowUnsignedRelease) {
        throw GradleException(
            "Release signing is not configured: " + signingProblems.joinToString("; ") + ". " +
                "Create the upload key and android/key.properties (storeFile, storePassword, " +
                "keyAlias, keyPassword) as described in docs/PLAY_RELEASE.md. " +
                "The debug key is never used for release builds."
        )
    }
}
