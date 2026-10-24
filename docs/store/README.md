# Store presence: icons, listing and privacy answers

**Status: draft for owner, clinical and legal review.** Nothing here has been
uploaded to Google Play or App Store Connect. Store copy about health needs
clinician review, and the privacy answers need counsel.

## Contents

| What | Where |
|---|---|
| Master logo artwork | `tool/brand/tether_mark.svg` |
| Icon and graphic generator | `tool/brand/generate_icons.py` |
| iOS app icon (every size in `Contents.json`, 1024 marketing icon opaque) | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` |
| Android adaptive icon (background, foreground, monochrome) | `android/app/src/main/res/mipmap-anydpi-v26/` |
| Android legacy launcher icons | `android/app/src/main/res/mipmap-*dpi/ic_launcher.png` |
| Google Play hi-res icon, 512 x 512 | `docs/store/play-icon-512.png` |
| Google Play feature graphic, 1024 x 500 | `docs/store/feature-graphic.png` |
| Google Play listing text (en-US) | `docs/store/metadata/android/en-US/` |
| App Store listing text (en-US) | `ios/fastlane/metadata/en-US/` |
| Data safety (Play) and App Privacy (Apple) draft answers | `docs/store/data-safety.md` |
| iOS privacy manifest | `ios/Runner/PrivacyInfo.xcprivacy` |
| Description for the future multi-program build (held back) | `docs/store/listing-multi-program.md` |

Checks: `test/store/store_assets_test.dart` (icon sizes, no Flutter default
icon, adaptive layers, listing lengths and wording).

## The logo

The mark is the logo in the design's screen header (Welcome and Today): a
brand-teal circle (`#123C37`) with a lime (`#D5EF75`) leaf outline, next to
the wordmark "Tether Health" in bold. The geometry is taken from the design's
CSS (`specs-and-design/tether_ui/generator/render_html.py`, `.logo i` and `.logo i::after`); see
the comment in `tether_mark.svg` for the derivation. Rendered at the design's
size and compared with the mark in the design's Welcome screenshot, the leaf's
angle differs by about 1 degree and its spread by under half a pixel.

Note: the Flutter kit's header widget (`TLogoMark` in
`specs-and-design/tether_ui/flutter/lib/ui/components.dart`) draws Material's `eco_rounded`
icon instead of this leaf, so the in-app header and the design screenshots
differ. The icons follow the design screenshots.

- **iOS:** the leaf on full-bleed teal; iOS applies its own rounded mask. No
  transparency anywhere in the set.
- **Android 8+:** adaptive icon. The design's 32-unit circle maps onto the
  72dp visible area, so a round launcher mask shows exactly the design's mark;
  the leaf stays inside the 66dp safe zone. The monochrome layer is used for
  Android 13 themed icons.
- **Android 7.1 and older:** the round mark at 44 of 48dp.
- **Play icon:** full-bleed square (Play applies its own mask).
- **Feature graphic:** the header lockup (mark and wordmark) at 5x on the
  Welcome screen's background gradient. No claims or taglines.

Regenerate after changing the SVG:

```sh
python3 tool/brand/generate_icons.py          # rewrite every output
python3 tool/brand/generate_icons.py --check  # exit 1 if any output is stale
```

It needs `rsvg-convert` (librsvg) and Pillow; nothing is added to
`pubspec.yaml`. The wordmark uses the installed Helvetica Neue Bold (the
design's header font), so check the feature graphic by eye when regenerating
on another machine.

## Listing copy (en-US)

The copy describes **what release builds contain today**: BreatheFree,
Heartwise, Steady and ClearAir, guest use with data kept on the phone,
email accounts, export and deletion. Release builds do not include the other
seven design programs, Sign in with Apple or Google, or health record import
(`lib/app/ui_selection.dart:15-26`), so the listing does not mention them. The
eleven-program description is ready in `listing-multi-program.md` for when a
build ships them.

Sources: the design's Welcome screen ("Care that meets you where you are." /
"Small steps, practical support and no judgment, for the parts of your health
you choose."), `specs-and-design/tether_ui/spec/programs.json`, and the program screens in
`lib/programs/`. No "treats", "cures", "diagnoses" or "clinically proven"; the
test enforces a list of such words.

| Field | Text | Limit |
|---|---|---|
| Play title / App Store name | Tether Health | 30 |
| Play short description | Small steps and practical support for the parts of your health you choose. | 80 |
| App Store subtitle | Small steps, practical support | 30 |
| App Store keywords | quit smoking,nicotine,blood pressure,cholesterol,glucose,diabetes,asthma,action plan,self-care | 100 |
| App Store promotional text | Care that meets you where you are. Small steps, practical support and no judgment, for the parts of your health you choose. | 170 |

URLs (pages checked in the website repository's production branch):

- Privacy: `https://www.tetherhealthgroup.com/privacy`. **Blocker:** the page
  says it covers the website only. An app privacy policy covering health and
  account data must be published (at this URL or another) before either store
  submission. A draft exists in the website repository but is not built.
- Terms: `https://www.tetherhealthgroup.com/terms` (neither store's listing
  has a terms field; link it from the app and the privacy policy).
- Support: `https://www.tetherhealthgroup.com/support`.
- Marketing: `https://www.tetherhealthgroup.com/`.
- Web account deletion (Play requires it): **not published. Blocker.**

Spanish: the app has Spanish strings, but there is no approved Spanish store
copy, so no `es-US` / `es-MX` listing is included.

### Why the Play text is not in `android/fastlane/metadata`

The owner's upload lanes refuse to run when `android/fastlane` holds anything
besides `Appfile`, `Fastfile`, `README.md` and `report.xml`
(`android/fastlane/Fastfile`, `before_all`), and the lanes never upload
metadata (`skip_upload_metadata: true`). So the Play text lives in
`docs/store/metadata/android/en-US/`, in fastlane supply's layout. Paste it
into Play Console, or move it under `android/fastlane/` together with a
reviewed change to that `before_all` check.

## Categories and ratings (suggestions)

- **Google Play:** category Health & Fitness. Medical is possible but invites
  stricter review; Health & Fitness fits self-care tracking. Complete the
  Health apps declaration under App content.
- **App Store:** primary Health & Fitness, secondary Medical.
- **Content rating (IARC questionnaire for Play; Apple age rating):**
  - References to tobacco: yes, in a quit-support context only; no sale or
    promotion.
  - Medical or treatment information: mild, self-care information; the app
    links to 911 and 1-800-QUIT-NOW by phone.
  - No violence, sexual content, gambling, purchases or ads.
  - No user-to-user communication or public user content.
  - No location sharing.
  - Suggested result: Play "Everyone" or "Teen" depending on the tobacco
    answers; Apple 12+ or higher. Confirm in each questionnaire.
- Apple guideline 5.1.1(ix): health apps must be submitted by the legal entity
  that provides the service (an organization developer account).

## Export compliance (App Store)

`ios/Runner/Info.plist` sets `ITSAppUsesNonExemptEncryption` to `false`. The
app uses only HTTPS and the operating system's own encryption (Keychain,
Android Keystore through `flutter_secure_storage`), which is exempt. App Store
Connect then stops asking the encryption question for each build. If the app
ever adds its own or non-standard encryption, change this value and file the
export documentation first.

## iOS privacy manifest

`ios/Runner/PrivacyInfo.xcprivacy` (in the Runner target's resources):

- No tracking, no tracking domains.
- Collected data types: email address, name, user ID, health, photos, other
  user content; all linked to the member, none used for tracking, purpose App
  Functionality. Matches `data-safety.md`.
- Required-reason APIs: file timestamp `C617.1`, system boot time `35F9.1`,
  UserDefaults `CA92.1`. Flutter.framework declares the first two in its own
  manifest; `shared_preferences_foundation` (pulled in by `supabase_flutter`)
  declares UserDefaults in its own; the Runner target's Swift code uses none
  of these APIs. The entries cover the same APIs for code linked into the app
  binary. Apple's upload check (ITMS-91053) can only be confirmed on upload.

## Still needed before submission

1. App privacy policy URL that covers the app (counsel, owner).
2. Web account deletion page (counsel, owner).
3. Clinician review of the listing copy; counsel review of the privacy answers.
4. Production Supabase and API hosts confirmed, for the privacy answers.
5. Phone screenshots (synthetic data only) for both stores; not produced here.
6. The in-app "Privacy policy, terms and help" row still shows a placeholder.
7. The in-app version row says "BreatheFree version 1.0.0 (100)" while the app
   name is Tether Health (`lib/screens/settings_privacy_screen.dart:636`).
