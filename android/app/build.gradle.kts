import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing, read from a file that is never committed.
//
// `android/key.properties` holds storeFile, storePassword, keyAlias and
// keyPassword. It is listed in .gitignore, and so is the keystore itself: a
// signing key in version control is a signing key that belongs to everyone who
// has ever cloned the repository, and for a Play listing it cannot be rotated
// without publishing a new app.
//
// When the file is absent — every clone, every CI run that only builds debug —
// the release build falls back to the debug key and says so. That is a
// deliberate choice over failing the build: `flutter run --release` has to keep
// working for anyone who wants to check performance, and CI builds a debug APK
// for reviewers. What must not happen is a release going to Play signed with a
// key everybody has, so `verifyReleaseSigning` below turns that into an error
// at the one moment it matters.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKey = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.TetherHealthLLC.tetherhealth"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.TetherHealthLLC.tetherhealth"
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
        if (hasReleaseKey) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // Left off on purpose. The app has three runtime dependencies and
            // no reflection-based serialisation, so shrinking buys little; what
            // it costs is a stack trace from a patient device that nobody can
            // read without a mapping file this project does not upload anywhere.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Pigeon 28 generates suspend functions for the @async methods on the
    // Unplug channel, so the generated Kotlin needs coroutines on the classpath.
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
}

flutter {
    source = "../.."
}

// Fails a Play-bound build that would go out signed with the debug key.
//
// The fallback above exists so `flutter run --release` and CI keep working
// without a keystore. This is the guard that stops that convenience becoming a
// shipped artifact: an app bundle is the only thing Play accepts, so wiring the
// check to the bundle tasks catches the real release path and leaves APK and
// debug builds alone.
//
// Run it directly to check a machine is set up:  ./gradlew verifyReleaseSigning
tasks.register("verifyReleaseSigning") {
    doLast {
        check(hasReleaseKey) {
            "This build would be signed with the debug key. Create " +
                "android/key.properties with storeFile, storePassword, " +
                "keyAlias and keyPassword before producing a release bundle. " +
                "See PRODUCTION_RELEASE_CHECKLIST.md."
        }
    }
}

tasks.matching { it.name == "bundleRelease" }.configureEach {
    dependsOn("verifyReleaseSigning")
}
