# Platform manifests

Every file that declares what the app may do on a platform, what it declares,
and the tests that pin it. Paths are from the repository root. When a manifest
changes, update this page and the guard test in the same change.

## Android

| File | Declares |
| --- | --- |
| `android/app/src/main/AndroidManifest.xml` | **Permissions:** `android.permission.INTERNET` only. **Application:** label `Tether Health`, `allowBackup="false"`, `localeConfig="@xml/locales_config"` (`android/app/src/main/res/xml/locales_config.xml`), icon `@mipmap/ic_launcher`. **Activities:** one, `.MainActivity` (exported, `singleTop`), with the `MAIN`/`LAUNCHER` filter and a `VIEW`/`BROWSABLE` filter for `com.tetherhealthllc.tetherhealth://login-callback` (auth redirect). **Queries:** intents `android.intent.action.TTS_SERVICE` and `android.intent.action.PROCESS_TEXT` (`text/plain`). Meta-data `flutterEmbedding=2`. |
| `android/app/src/debug/AndroidManifest.xml` | `INTERNET` only, for Flutter tooling in debug builds. |
| `android/app/src/profile/AndroidManifest.xml` | `INTERNET` only, for Flutter tooling in profile builds. |

## iOS

| File | Declares |
| --- | --- |
| `ios/Runner/Info.plist` | **Usage strings:** `NSPhotoLibraryUsageDescription` only (profile photo). **URL schemes:** `CFBundleURLSchemes` = `com.tetherhealthllc.tetherhealth`. **Export compliance:** `ITSAppUsesNonExemptEncryption` = `false`. **Localizations:** `CFBundleLocalizations` = `en`, `es`. Also `CFBundleDisplayName` `Tether Health`, `TetherAppGroupIdentifier` = `$(TETHER_APP_GROUP_IDENTIFIER)`, and the scene manifest (`SceneDelegate`). |
| `ios/Runner/DebugProfile.entitlements` | `keychain-access-groups` = `$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)`. Used by the Runner Debug configuration. |
| `ios/Runner/Release.entitlements` | Same keychain group. Used by the Runner Release and Profile configurations. |
| `ios/Runner/Runner.entitlements` | `com.apple.developer.family-controls` and app group `group.com.TetherHealthLLC.tetherhealth.unplug`. Not referenced by `CODE_SIGN_ENTITLEMENTS` in `ios/Runner.xcodeproj/project.pbxproj`, so it is not signed into any build today. |
| `ios/Runner/PrivacyInfo.xcprivacy` | `NSPrivacyTracking` = `false`, no tracking domains. Collected data types, all linked, not tracking, purpose App Functionality: EmailAddress, Name, UserID, Health, PhotosorVideos, OtherUserContent. Required-reason APIs: FileTimestamp `C617.1`, SystemBootTime `35F9.1`, UserDefaults `CA92.1`. Bundled as a Runner resource. |
| `ios/UnplugMonitor/Info.plist`, `ios/UnplugShield/Info.plist`, `ios/UnplugShieldAction/Info.plist` | Extension points `com.apple.deviceactivity.monitor-extension`, `com.apple.ManagedSettings.shield-app-configuration-service` and `com.apple.ManagedSettings.shield-app-action-service`. |
| `ios/UnplugMonitor/UnplugMonitor.entitlements`, `ios/UnplugShield/UnplugShield.entitlements`, `ios/UnplugShieldAction/UnplugShieldAction.entitlements` | App group `group.com.TetherHealthLLC.tetherhealth.unplug`; the monitor also has `family-controls`. The three extension targets are not in `project.pbxproj` today, so none of these files is built. |

## Guard tests

| Test | Pins |
| --- | --- |
| `test/android_internet_permission_test.dart` | The main manifest declares `INTERNET`. |
| `test/auth/auth_deep_link_config_test.dart` | iOS registers exactly the redirect scheme; Android registers exactly the redirect scheme and host; no platform file keeps the previous scheme. |
| `test/l10n/platform_locales_test.dart` | `CFBundleLocalizations` and `locales_config.xml` equal the release locales (`en`, `es`); the application points at `locales_config.xml`. |
| `test/store/store_assets_test.dart` | The manifest uses `@mipmap/ic_launcher`; the privacy manifest declares no tracking, lists the six data types and is a Runner resource; `ITSAppUsesNonExemptEncryption` is `false`. |
| `test/config/app_identity_test.dart` | `.MainActivity` and no `package=` in the manifest; the Info.plist app group key; no retired app ID in either file. |
| `test/no_third_party_sdks_test.dart` | No forbidden SDK in the main manifest or Info.plist. |
