# Production release checklist

## Product and clinical

- Confirm the intended use and whether any feature could be regulated as a medical device.
- Complete clinician review of medication, withdrawal, pregnancy and urgent-symptom content.
- Validate jurisdiction-specific quitline and emergency routing.
- Professionally translate and clinically review Spanish and any additional languages.
- Run usability testing with people who smoke, including low-literacy and disability cohorts.

## Privacy and security

- Complete data-flow mapping, threat modeling and a privacy impact assessment.
- Implement OAuth/OIDC with short-lived tokens and secure device storage.
- Encrypt protected data in transit and at rest.
- Enforce consent versioning, purpose limitation and revocation server-side.
- Implement verified exports and deletion with auditable completion.
- Keep sensitive notification text off by default.
- Add abuse prevention, rate limiting, monitoring and incident-response procedures.
- Commission mobile, API and cloud penetration testing.

## Accessibility

- Replace bitmap bodies with native widgets where dynamic text reflow is required.
- Test VoiceOver, TalkBack, keyboard-only navigation and switch control.
- Verify 200% text scaling, 4.5:1 contrast, reduced motion and color-independent meaning.
- Provide captions and transcripts for all audio/video education.

## iOS

- Choose the final bundle identifier and Apple Development Team.
- Configure signing, App Store Connect, privacy nutrition labels and age rating.
- Add reviewed purpose strings for every requested iOS permission.
- Test on current and minimum-supported iOS versions and multiple screen sizes.
- Archive with `flutter build ipa --release` on macOS and distribute through TestFlight first.

## Android

- Choose the final application ID. It is permanent once published — Play matches
  updates on it — and the current value (`com.breathefree.breathefree_patient`)
  does not follow the `com.tetherhealthgroup.*` namespace the sibling Chronic
  Care app uses. Settle this before the first upload.
- Create a protected upload keystore. **The Gradle wiring is in place**:
  `android/app/build.gradle.kts` reads `android/key.properties` (gitignored) and
  signs the release build with it. Copy `android/key.properties.example`, run the
  `keytool` command in it, and keep the keystore somewhere durable — losing it
  means the Play listing can never be updated again. Until that file exists the
  release build prints a warning and falls back to the debug keystore, which the
  Play Store rejects; verify any candidate artifact with
  `apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk`
  and confirm the signer is *not* `CN=Android Debug`.
- Complete the Google Play Data safety form and content rating.
- Review Android permissions and notification channels.
- Build an App Bundle with `flutter build appbundle --release` and test through internal sharing.

## Desktop and web

- Sign Windows and macOS production binaries.
- Configure secure deep links and update distribution.
- Apply CSP, HTTPS-only transport and secure storage rules for web/PWA deployments.
- Confirm responsive behavior for keyboard, pointer and screen readers.

## Quality gates

- `flutter analyze` returns no errors.
- `flutter test` passes.
- Integration tests pass on iOS and Android physical devices.
- Offline actions synchronize once without duplication.
- No slip automatically resets prior progress.
- Consent checks protect every external share.
- Crash reporting contains no health-entry payloads.
- Release candidates pass clinical, privacy, security and accessibility approval.
