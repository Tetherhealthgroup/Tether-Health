import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The rule: this app ships no third-party SDK that reports on a person — no
// analytics, no crash reporters that collect identifiers, no session replay,
// no ad or attribution SDK — including one pulled in through a transitive or
// native dependency, which is where it is easiest to break by accident.
//
// This file is where that rule is written down and enforced on this branch.
// It was first stated for child profiles in the Unplug v2.1 addendum (§3.2),
// which is not part of this branch; docs/ARCHITECTURE.md separately keeps
// health payloads out of analytics and crash reports.
//
// An audit done once is a fact about the day it was done. These tests are the
// audit turned into something that fails the build, which is the only version
// of it that survives the next person adding a package in a hurry.

/// Why a forbidden name fails, quoted in every failure message.
const _rule = 'This app ships no SDK that reports on a person — analytics, '
    'ads, attribution, crash reporters that collect identifiers, session '
    'replay — including through a transitive or native dependency (top of '
    'test/no_third_party_sdks_test.dart). An allowlist cannot override this.';

/// Vendor and SDK-family names that identify an SDK which phones home about a
/// person, serves ads to them, records their session, or tracks them for a
/// vendor.
///
/// A name is forbidden when one of these is a word of it, or several adjacent
/// words joined ([forbiddenFamilyOf]), so `firebase_core`, `sentry_flutter`,
/// `customer_io`, `FirebaseAnalytics`, `AppsFlyerFramework` and
/// `com.google.firebase:firebase-bom` are all caught. This check runs on its
/// own, after the allowlists: a name here stays forbidden even if somebody
/// also allowlists it.
///
/// Known false positives, accepted because failing closed is the safer error:
/// - Families that are also ordinary words (`ads`, `adjust`, `branch`,
///   `clarity`, `embrace`, `heap`, `intercom`, `measurement`, `purchases`,
///   `segment`, `singular`, `telemetry`) match unrelated names that use the
///   word, e.g. a `heap_sort` package or a `branch` coordinate.
/// - Joined adjacent words can spell a family by accident (`data` + `transport`
///   in a name that has nothing to do with Google's DataTransport).
/// - The whole-file scan below matches these words in comments and strings of
///   the scanned files, not only in dependency names.
/// To resolve one, do not rename around the check: change this list in the
/// same change, with the reason in a comment next to the edit (for example,
/// replace a broad family with the specific names in [forbiddenPackages]),
/// and have it reviewed like any allowlist change.
const forbiddenFamilies = <String>[
  'adjust',
  'admob',
  'ads',
  'agconnect',
  'airship',
  'amplitude',
  'analytics',
  'appcenter',
  'appdynamics',
  'applovin',
  'appmeasurement',
  'appmetrica',
  'appsflyer',
  'branch',
  'braze',
  'bugsnag',
  'clarity',
  'clevertap',
  'contentsquare',
  'countly',
  'crashlytics',
  'customerio',
  'datatransport',
  'datadog',
  'dynatrace',
  'embrace',
  'facebook',
  'fbsdk',
  'firebase',
  'flurry',
  'fullstory',
  'glassbox',
  'heap',
  'hotjar',
  'instabug',
  'intercom',
  'ironsource',
  'kochava',
  'launchdarkly',
  'logrocket',
  'matomo',
  'measurement',
  'mixpanel',
  'moengage',
  'newrelic',
  'onesignal',
  'opentelemetry',
  'pendo',
  'posthog',
  'purchases',
  'quantummetric',
  'raygun',
  'revenuecat',
  'rollbar',
  'rudder',
  'segment',
  'sentry',
  'singular',
  'smartlook',
  'statsig',
  'telemetry',
  'umeng',
  'userexperior',
  'uxcam',
];

/// Whole package names forbidden outright, for SDKs whose name is not a single
/// vendor word. Kept explicit so the intent is readable without the word rule.
const forbiddenPackages = <String>[
  'customer_io',
  'google_analytics',
  'google_mobile_ads',
  'opentelemetry',
  'raygun4flutter',
];

/// Runtime packages this app is allowed to ship, each with the reason.
///
/// Adding to this list is a decision about what leaves a patient device, and
/// the reason belongs here next to the name. An entry does not require the
/// package to be a dependency; it only permits it. A reason that still says
/// "review pending" is only acceptable while the package is absent.
const allowedRuntimePackages = <String, String>{
  'flutter': 'The Flutter SDK itself.',
  'flutter_secure_storage':
      'Keeps the session token in the Keychain / Android Keystore, not in '
          'shared preferences.',
  'flutter_tts':
      'Speaks rescue guidance aloud through the OS speech engine (vendored '
          'under third_party/); the OS may use network voices, the plugin '
          'sends nothing itself.',
  'http': 'Talks to our own API (profile, quit plan, programs, account data).',
  'image_picker':
      'Picks a profile avatar from the camera or photo library; on-device '
          'only, the upload goes to our own Supabase storage.',
  'supabase_flutter':
      'Our Supabase project (vendor/processor; BAA/DPA status to confirm).',
  'url_launcher':
      'Opens the dialer for 988, 911 and the quitlines, and support URLs; it '
          'hands a URI to the platform and has no network access of its own.',
  // Pre-approved; not yet a dependency.
  'sign_in_with_apple':
      'Owner decision P-09 (2026-10-17); th-security review pending (TH-935)',
  'google_sign_in':
      'Owner decision P-09 (2026-10-17); th-security review pending (TH-935)',
};

/// Android (Maven) dependencies the build may declare, as `group:artifact`,
/// each with the reason.
///
/// Every Gradle configuration counts — `implementation`, `api`,
/// `runtimeOnly`, `compileOnly`, `kapt`, `ksp`, `classpath`, variant forms
/// such as `debugImplementation`, and test configurations such as
/// `testImplementation`. Test-only libraries are not exempt: they are allowed
/// explicitly here, with a reason that says they are test-only.
const allowedNativeDependencies = <String, String>{
  'com.android.tools.build:gradle':
      'Android Gradle Plugin on the vendored flutter_tts buildscript '
          'classpath; build-time only, not shipped.',
  'org.jetbrains.kotlin:kotlin-gradle-plugin':
      'Kotlin Gradle plugin on the vendored flutter_tts buildscript classpath; '
          'build-time only, not shipped.',
  'org.jetbrains.kotlin:kotlin-stdlib':
      'Kotlin standard library, used by the vendored flutter_tts plugin; it '
          'collects nothing and talks to nobody.',
  // Pre-approved; not yet dependencies.
  'org.jetbrains.kotlinx:kotlinx-coroutines-android':
      'Kotlin coroutines runtime for Pigeon-generated @async channels; '
          'allowed by the earlier org.jetbrains.kotlinx rule of this guard.',
  'org.jetbrains.kotlinx:kotlinx-coroutines-core':
      'Kotlin coroutines runtime for Pigeon-generated @async channels; '
          'allowed by the earlier org.jetbrains.kotlinx rule of this guard.',
  'androidx.health.connect:connect-client':
      'Owner decision P-46 (2026-10-17), Android exception for Health '
          'Connect; review pending (TH-962)',
};

/// Gradle plugin ids the build may apply, each with the reason.
const allowedGradlePlugins = <String, String>{
  'com.android.application':
      'Android Gradle Plugin for the app module; build-time only.',
  'com.android.library':
      'Android Gradle Plugin for the vendored flutter_tts module; build-time '
          'only.',
  'dev.flutter.flutter-gradle-plugin':
      "Flutter's own Gradle plugin, from the Flutter SDK.",
  'dev.flutter.flutter-plugin-loader':
      "Flutter's own plugin loader, from the Flutter SDK.",
  'org.jetbrains.kotlin.android': 'Kotlin Gradle plugin; build-time only.',
};

/// Remote Swift packages the iOS project may reference directly (in
/// `project.pbxproj`) or a vendored plugin may fetch (a `url:` in its
/// `Package.swift`). Empty: Flutter's Swift Package Manager integration adds
/// only a local package ([allowedLocalSwiftPackages]); plugin packages are
/// resolved inside it, not referenced by the project.
const allowedSwiftPackageUrls = <String, String>{};

/// Local Swift packages `project.pbxproj` may reference, by relative path.
const allowedLocalSwiftPackages = <String, String>{
  'Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage':
      "Flutter's own Swift Package Manager integration: a generated local "
          "package that links the plugins' native code into Runner.",
};

/// Scripts `web/index.html` may load, by `src`. Inline scripts are not
/// allowed: an analytics snippet is usually one.
const allowedWebScripts = <String, String>{
  'flutter_bootstrap.js':
      "Flutter's own web loader, generated by `flutter build web`.",
};

/// The lower-case words of [name]: split at anything that is not a letter or
/// digit, at camelCase boundaries and around digits, so `AppsFlyerFramework`
/// is `apps flyer framework` and `raygun4flutter` is `raygun 4 flutter`.
List<String> nameWords(String name) => [
      for (final piece in name.split(RegExp(r'[^A-Za-z0-9]+')))
        for (final match
            in RegExp(r'[A-Z]+(?![a-z])|[A-Z]?[a-z]+|[0-9]+').allMatches(piece))
          match.group(0)!.toLowerCase(),
    ];

/// The forbidden family [name] belongs to, or `null` if it is not one.
///
/// Works on Dart package names, CocoaPods and Swift package names, Maven
/// coordinates, Gradle plugin ids and URLs alike: [name] is forbidden when it
/// is in [forbiddenPackages], or when one of its [nameWords], or several
/// adjacent words joined, is in [forbiddenFamilies].
String? forbiddenFamilyOf(String name) {
  final lower = name.toLowerCase();
  if (forbiddenPackages.contains(lower)) return lower;
  final words = nameWords(name);
  for (var start = 0; start < words.length; start++) {
    var joined = '';
    for (var end = start; end < words.length; end++) {
      joined += words[end];
      if (forbiddenFamilies.contains(joined)) return joined;
    }
  }
  return null;
}

/// Allowlisted names that are present but whose reason still says the review
/// is pending. An absent package may stay pre-approved pending review; a
/// present one must carry what was reviewed.
List<String> presentButPendingReview(
  Map<String, String> allowlist,
  Iterable<String> present,
) {
  final pending =
      RegExp(r'review\s+pending|pending\s+review', caseSensitive: false);
  final presentNames = present.toSet();
  return [
    for (final entry in allowlist.entries)
      if (presentNames.contains(entry.key) && pending.hasMatch(entry.value))
        entry.key,
  ];
}

String _unquote(String value) {
  final v = value.trim();
  if (v.length >= 2 &&
      ((v.startsWith('"') && v.endsWith('"')) ||
          (v.startsWith("'") && v.endsWith("'")))) {
    return v.substring(1, v.length - 1);
  }
  return v;
}

/// Whether [line] is the top-level YAML key [key], quoted or not, with or
/// without a space before the colon.
bool _isTopLevelKey(String line, String key) =>
    RegExp('^(["\']?)$key\\1\\s*:').hasMatch(line);

/// Top-level package names in the `dependencies:` block of a pubspec — not
/// `dev_dependencies:`, which never ship. Accepts quoted keys (`"collection":`)
/// and a space before the colon (`collection :`).
///
/// Secondary to [directRuntimeDependencies]: `pubspec.lock` is the authority.
List<String> runtimeDependencyNames(List<String> pubspec) {
  final start = pubspec.indexWhere(
    (line) => _isTopLevelKey(line, 'dependencies'),
  );
  if (start == -1) return const [];
  final names = <String>[];
  for (final line in pubspec.skip(start + 1)) {
    // The block ends at the next top-level key.
    if (RegExp(r'^[^\s#]').hasMatch(line)) break;
    // Top-level entries are indented exactly two spaces; anything deeper is a
    // constraint such as `sdk: flutter` or `path: third_party/flutter_tts`.
    final match = RegExp(
      r'''^  (["']?)([A-Za-z0-9_]+)\1\s*:''',
    ).firstMatch(line);
    if (match != null) names.add(match.group(2)!);
  }
  return names;
}

/// Whether a pubspec declares a `dependency_overrides:` block.
bool hasDependencyOverrides(List<String> pubspec) =>
    pubspec.any((line) => _isTopLevelKey(line, 'dependency_overrides'));

/// One entry of the `packages:` map in a `pubspec.lock`.
class LockedPackage {
  LockedPackage(this.name);

  final String name;
  String? dependency;
  String? source;

  /// Scalar `description:`, e.g. `flutter` for SDK packages.
  String? description;

  /// Mapping `description:` fields, e.g. `name`, `url`, `path`, `relative`.
  final Map<String, String> descriptionFields = {};

  @override
  String toString() => '$name ($dependency, $source, '
      '${description ?? descriptionFields})';
}

/// Every package resolved in a `pubspec.lock`, direct and transitive.
List<LockedPackage> parseLock(List<String> lock) {
  final start = lock.indexWhere((line) => _isTopLevelKey(line, 'packages'));
  if (start == -1) return const [];
  final packages = <LockedPackage>[];
  LockedPackage? current;
  var inDescription = false;
  for (final line in lock.skip(start + 1)) {
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
    if (RegExp(r'^\S').hasMatch(line)) break;

    final entry = RegExp(r'^  (\S.*?)\s*:\s*$').firstMatch(line);
    if (entry != null) {
      current = LockedPackage(_unquote(entry.group(1)!));
      packages.add(current);
      inDescription = false;
      continue;
    }
    if (current == null) continue;

    final field = RegExp(r'^    ([A-Za-z_-]+)\s*:\s*(.*)$').firstMatch(line);
    if (field != null) {
      final key = field.group(1)!;
      final value = _unquote(field.group(2)!);
      inDescription = key == 'description' && value.isEmpty;
      switch (key) {
        case 'dependency':
          current.dependency = value;
        case 'source':
          current.source = value;
        case 'description':
          if (value.isNotEmpty) current.description = value;
      }
      continue;
    }

    final sub = RegExp(r'^      ([A-Za-z_-]+)\s*:\s*(.*)$').firstMatch(line);
    if (sub != null && inDescription) {
      current.descriptionFields[sub.group(1)!] = _unquote(sub.group(2)!);
    }
  }
  return packages;
}

/// Names of the packages the app depends on directly at runtime, as resolved.
List<String> directRuntimeDependencies(List<LockedPackage> packages) => [
      for (final package in packages)
        if (package.dependency == 'direct main' ||
            package.dependency == 'direct overridden')
          package.name,
    ];

/// Why [package] comes from a source this app does not accept, or `null`.
///
/// Accepted: `hosted` on https://pub.dev, `sdk`, and a relative `path` under
/// `third_party/`. Anything else — git, another host, another path — is a
/// way to ship code the allowlist never saw.
String? sourceViolation(LockedPackage package) {
  switch (package.source) {
    case 'hosted':
      final url = package.descriptionFields['url'];
      return url == 'https://pub.dev'
          ? null
          : 'hosted on "$url", not https://pub.dev';
    case 'sdk':
      return null;
    case 'path':
      final path = package.descriptionFields['path'] ?? '';
      final relative = package.descriptionFields['relative'] == 'true';
      final segments = path.split('/');
      final underThirdParty = relative &&
          segments.length >= 2 &&
          segments.first == 'third_party' &&
          !segments.contains('..') &&
          !path.contains(r'\');
      return underThirdParty ? null : 'path "$path" is not under third_party/';
    default:
      return 'source "${package.source}" is not hosted, sdk or path';
  }
}

// --- iOS -------------------------------------------------------------------

/// The `field` value of every object of class [isa] in a `project.pbxproj`,
/// e.g. the `repositoryURL` of each `XCRemoteSwiftPackageReference`. An object
/// without the field is reported as `<no field>`, so it cannot pass an
/// allowlist by being unreadable.
List<String> pbxprojObjectField(
  String pbxproj, {
  required String isa,
  required String field,
}) {
  final anyIsa = RegExp(r'\bisa\s*=');
  final value = RegExp('\\b$field\\s*=\\s*(?:"([^"]*)"|([^;\\s]+))\\s*;');
  return [
    for (final match
        in RegExp('\\bisa\\s*=\\s*"?$isa"?\\s*;').allMatches(pbxproj))
      () {
        final next = anyIsa.allMatches(pbxproj, match.end).firstOrNull;
        final object =
            pbxproj.substring(match.end, next?.start ?? pbxproj.length);
        final found = value.firstMatch(object);
        return found == null
            ? '<no $field>'
            : (found.group(1) ?? found.group(2))!;
      }(),
  ];
}

/// Every `url:` in a `Package.swift` — remote packages and binary targets.
List<String> swiftManifestUrls(String manifest) => [
      for (final match in RegExp(r'\burl\s*:\s*"([^"]+)"').allMatches(manifest))
        match.group(1)!,
    ];

/// The identity and location of every pin in a SwiftPM `Package.resolved`
/// (format 1, 2 or 3), or `null` if the file cannot be read as one.
List<String>? swiftResolvedPins(String resolved) {
  final Object? decoded;
  try {
    decoded = jsonDecode(resolved);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) return null;
  final object = decoded['object'];
  final pins = decoded['pins'] ?? (object is Map ? object['pins'] : null);
  if (pins is! List) return null;
  return [
    for (final pin in pins)
      if (pin is Map)
        for (final key in ['identity', 'package', 'location', 'repositoryURL'])
          if (pin[key] is String) pin[key] as String,
  ];
}

/// Pod names in a `Podfile.lock`: every entry and nested dependency under
/// `PODS:` and every key under `SPEC CHECKSUMS:`. Subspecs stay whole
/// (`Firebase/Analytics`).
List<String> podNames(List<String> podfileLock) {
  final names = <String>{};
  String? section;
  for (final line in podfileLock) {
    if (line.trim().isEmpty) continue;
    if (RegExp(r'^\S').hasMatch(line)) {
      section = line.trim();
      continue;
    }
    final match = switch (section) {
      'PODS:' => RegExp(r'''^\s+-\s+["']?([^\s"'(:]+)''').firstMatch(line),
      'SPEC CHECKSUMS:' =>
        RegExp(r'''^\s+["']?([^\s"':]+)["']?\s*:''').firstMatch(line),
      _ => null,
    };
    if (match != null) names.add(match.group(1)!);
  }
  return names.toList();
}

// --- Android ---------------------------------------------------------------

/// The dependency configurations Gradle accepts: the base ones, their variant
/// and test forms (`debugImplementation`, `testImplementation`, `kaptTest`,
/// ...), and `classpath`.
const _configurationPattern =
    r'(?:[a-z][A-Za-z0-9]*)?(?:[Ii]mplementation|[Aa]pi|[Cc]ompileOnly'
    r'|[Rr]untimeOnly|[Aa]nnotationProcessor)'
    r'|kapt[A-Za-z0-9]*|ksp[A-Za-z0-9]*'
    r'|classpath|coreLibraryDesugaring|lintChecks|lintPublish|wearApp';

final _gradleConfiguration = RegExp(
  '(?<![A-Za-z0-9_.])($_configurationPattern)(?![A-Za-z0-9_])',
);

bool _isConfiguration(String name) =>
    RegExp('^(?:$_configurationPattern)\$').hasMatch(name);

final _identifierChar = RegExp(r'[A-Za-z0-9_]');

/// A Gradle file as a scanner sees it. [code] is the source with comments
/// blanked; [masked] also blanks the inside of every string literal (the
/// delimiters stay). Both keep the source's length and line breaks, so an
/// offset found in [masked] reads back from [code].
class GradleText {
  GradleText(this.code, this.masked);

  final String code;
  final String masked;
}

/// Whether the `/` at [i] opens a Groovy slashy string (`/g:a:v/`) rather
/// than dividing: it must be followed by a non-blank character that is not
/// `/` or `*`, and stand where an expression starts — at a line start, after
/// one of `( , = [ : { ; ! & | ?`, or after a configuration name and a space.
bool _slashyStringAt(String source, int i) {
  if (i + 1 >= source.length) return false;
  final next = source[i + 1];
  if (next == '/' || next == '*' || next.trim().isEmpty) return false;
  var j = i - 1;
  while (j >= 0 && (source[j] == ' ' || source[j] == '\t')) {
    j--;
  }
  if (j < 0 || source[j] == '\n') return true;
  if ('(,=[:{;!&|?'.contains(source[j])) return true;
  if (j < i - 1 && _identifierChar.hasMatch(source[j])) {
    var k = j;
    while (k >= 0 && _identifierChar.hasMatch(source[k])) {
      k--;
    }
    return _isConfiguration(source.substring(k + 1, j + 1));
  }
  return false;
}

/// Splits [source] into [GradleText]. String-aware: `//` and `/*` inside
/// `"..."`, `'...'`, `"""..."""`, `'''...'''` or a slashy string are text,
/// not comments, so `"**/*.so"` cannot hide what follows it.
GradleText scanGradle(String source) {
  final code = StringBuffer();
  final masked = StringBuffer();
  void keep(String c) {
    code.write(c);
    masked.write(c);
  }

  void blank(String c, {bool inString = false}) {
    final space = c == '\n' ? '\n' : ' ';
    code.write(inString ? c : space);
    masked.write(space);
  }

  var i = 0;
  while (i < source.length) {
    final c = source[i];
    if (source.startsWith('//', i)) {
      while (i < source.length && source[i] != '\n') {
        blank(source[i++]);
      }
      continue;
    }
    if (source.startsWith('/*', i)) {
      final end = source.indexOf('*/', i + 2);
      final stop = end == -1 ? source.length : end + 2;
      while (i < stop) {
        blank(source[i++]);
      }
      continue;
    }
    final delimiter = source.startsWith('"""', i)
        ? '"""'
        : source.startsWith("'''", i)
            ? "'''"
            : (c == '"' || c == "'")
                ? c
                : (c == '/' && _slashyStringAt(source, i))
                    ? '/'
                    : null;
    if (delimiter == null) {
      keep(c);
      i++;
      continue;
    }
    for (var k = 0; k < delimiter.length; k++) {
      keep(source[i++]);
    }
    while (i < source.length) {
      if (source.startsWith(delimiter, i)) {
        for (var k = 0; k < delimiter.length; k++) {
          keep(source[i++]);
        }
        break;
      }
      // A one-character delimiter does not span lines here; stopping at the
      // line end keeps an unbalanced quote from swallowing the file.
      if (delimiter.length == 1 && source[i] == '\n') break;
      if (source[i] == r'\' && i + 1 < source.length) {
        blank(source[i++], inString: true);
      }
      blank(source[i++], inString: true);
    }
  }
  return GradleText(code.toString(), masked.toString());
}

/// [source] with its comments blanked (string-aware, see [scanGradle]).
String stripGradleComments(String source) => scanGradle(source).code;

/// Every quoted Maven coordinate in a Gradle or version-catalog file, as
/// `group:artifact` (version dropped). Catches a coordinate however it is
/// used: a dependency in any configuration, `platform(...)`, `classpath`, a
/// variable, an inline catalog entry. Runs on the raw text, comments
/// included: a coordinate in a comment only makes the check fail closed.
List<String> mavenCoordinates(String source) => [
      for (final match in RegExp(
        r'''["']([A-Za-z][A-Za-z0-9_.\-]*):([A-Za-z0-9_.\-]+)(?::[^"'\s]*)?["']''',
      ).allMatches(source))
        '${match.group(1)}:${match.group(2)}',
    ];

/// One dependency declaration in a Gradle file.
class GradleDeclaration {
  GradleDeclaration(this.configuration, this.notation);

  final String configuration;

  /// The argument as written, e.g. `platform("g:a:1")` or `libs.foo`.
  final String notation;

  @override
  String toString() => '$configuration($notation)';
}

/// Offset of the bracket closing the one at [open] in a masked text (string
/// interiors are blank there, so every bracket left is code).
int _closingBracket(String masked, int open) {
  var depth = 0;
  for (var i = open; i < masked.length; i++) {
    final c = masked[i];
    if (c == '(' || c == '{' || c == '[') depth++;
    if ((c == ')' || c == '}' || c == ']') && --depth == 0) return i;
  }
  return masked.length;
}

/// The body ranges (after `{`, before `}`) of every `<name> { ... }` block in
/// a masked text, nested or not.
List<(int, int)> _blockBodies(String masked, String name) => [
      for (final match
          in RegExp('(?<![A-Za-z0-9_])$name\\s*\\{').allMatches(masked))
        (match.end, _closingBracket(masked, match.end - 1)),
    ];

String _lineFrom(String text, int start) {
  final end = text.indexOf('\n', start);
  return text.substring(start, end == -1 ? text.length : end).trim();
}

/// Every dependency declaration in a Gradle file, Kotlin or Groovy DSL:
///
/// - `configuration(...)` anywhere: `implementation("g:a:1")`,
///   `api(platform(...))`, `implementation(group = "g", name = "a")`;
/// - inside `dependencies { }`, a configuration name, a space and any
///   argument that does not start with `=`, `{` or `.`: `classpath 'g:a:1'`,
///   `implementation group: 'g', name: 'a'`, `implementation sdk`,
///   `implementation rootProject.ext.x`, `implementation /g:a:1/`;
/// - Kotlin's `"implementation"(...)`;
/// - `add("implementation", ...)`, also as `dependencies.add` or
///   `project.dependencies.add`.
List<GradleDeclaration> gradleDeclarations(String source) {
  final text = scanGradle(source);
  final code = text.code;
  final masked = text.masked;
  final blocks = _blockBodies(masked, 'dependencies');
  bool inDependencies(int offset) =>
      blocks.any((block) => offset >= block.$1 && offset < block.$2);
  final declarations = <GradleDeclaration>[];

  for (final match in _gradleConfiguration.allMatches(masked)) {
    var i = match.end;
    while (i < masked.length && (masked[i] == ' ' || masked[i] == '\t')) {
      i++;
    }
    if (i < masked.length && masked[i] == '(') {
      final close = _closingBracket(masked, i);
      declarations.add(GradleDeclaration(
          match.group(1)!, code.substring(i + 1, close).trim()));
    } else if (i > match.end &&
        i < masked.length &&
        !'={.\r\n'.contains(masked[i]) &&
        inDependencies(match.start)) {
      declarations.add(GradleDeclaration(match.group(1)!, _lineFrom(code, i)));
    }
  }

  for (final match
      in RegExp(r'''["']([A-Za-z][A-Za-z0-9]*)["']\s*\(''').allMatches(code)) {
    // The opening quote must be code, not the inside of another string.
    if (masked[match.start] == ' ' || !_isConfiguration(match.group(1)!)) {
      continue;
    }
    final open = match.end - 1;
    declarations.add(GradleDeclaration(match.group(1)!,
        code.substring(open + 1, _closingBracket(masked, open)).trim()));
  }

  for (final match in RegExp(
    r'''(?<![A-Za-z0-9_])add\s*\(\s*["']([A-Za-z][A-Za-z0-9]*)["']\s*,''',
  ).allMatches(code)) {
    if (masked.substring(match.start, match.start + 3) != 'add' ||
        !_isConfiguration(match.group(1)!)) {
      continue;
    }
    final open = masked.indexOf('(', match.start);
    declarations.add(GradleDeclaration(match.group(1)!,
        code.substring(match.end, _closingBracket(masked, open)).trim()));
  }
  return declarations;
}

/// `group:name` of a map-notation declaration (`group: 'g', name: 'a'` or
/// `group = "g", name = "a"`), or `null` when it is not one with literal
/// values.
String? mapNotationCoordinate(String notation) {
  String? field(String key) =>
      RegExp('(?<![A-Za-z0-9_])$key\\s*[:=]\\s*["\']([^"\']+)["\']')
          .firstMatch(notation)
          ?.group(1);
  final group = field('group');
  final name = field('name');
  return group != null && name != null ? '$group:$name' : null;
}

/// The coordinates a Gradle file declares: every quoted coordinate in it, and
/// every map-notation declaration.
List<String> gradleFileCoordinates(String source) => [
      ...mavenCoordinates(source),
      for (final declaration in gradleDeclarations(source))
        if (mapNotationCoordinate(declaration.notation) case final coordinate?)
          coordinate,
    ];

/// Every `libs.` version-catalog accessor in a Gradle file, without the
/// `libs.` prefix and without a trailing `.get()`: `libs.firebase.bom` is
/// `firebase.bom`, `libs.plugins.kotlin.android` is `plugins.kotlin.android`.
List<String> libsReferences(String source) => [
      for (final match
          in RegExp(r'(?<![A-Za-z0-9_.])libs((?:\.[A-Za-z_][A-Za-z0-9_]*)+)')
              .allMatches(stripGradleComments(source)))
        match
            .group(1)!
            .substring(1)
            .replaceFirst(RegExp(r'\.(get|asProvider|orNull)$'), ''),
    ];

/// Why [declaration] is a notation this file cannot check, or `null`.
///
/// Checkable: quoted coordinates and map notation with literal `group` and
/// `name` (each goes through the allowlist), and version-catalog references
/// (each must resolve, and every catalog entry goes through the allowlist),
/// optionally inside `platform(...)` or `enforcedPlatform(...)`. Everything
/// else — `files(...)`, `fileTree(...)`, `project(...)`, a variable, an ext
/// property, a slashy string, `kotlin("...")` — could ship code the
/// allowlist never saw.
String? unrecognisedNotation(GradleDeclaration declaration) {
  final notation = declaration.notation;
  if (RegExp(r'\b(files|fileTree|project)\s*\(').hasMatch(notation)) {
    return '$declaration is a local file or project dependency';
  }
  if (mapNotationCoordinate(notation) == null &&
      mavenCoordinates(notation).isEmpty &&
      libsReferences(notation).isEmpty) {
    return '$declaration is not a quoted group:artifact, map notation with '
        'literal group and name, or a libs. reference';
  }
  return null;
}

/// Problems with every `apply from: ...` / `apply(from = ...)` in the Gradle
/// file at [path]: the script must be a literal relative path that stays
/// inside `android/` or `third_party/`. A URL, an absolute path, an escape
/// with `..` or a computed value fails.
List<String> applyFromViolations(String path, String source) {
  final text = scanGradle(source);
  final problems = <String>[];
  for (final match in RegExp(r'(?<![A-Za-z0-9_])apply\s*\(?\s*from\s*[:=]\s*')
      .allMatches(text.masked)) {
    final written = _lineFrom(text.code, match.start);
    final literal = RegExp(r'''^(["'])([^"'\n]*)\1''')
        .firstMatch(text.code.substring(match.end));
    final target = literal?.group(2);
    if (target == null ||
        target.contains(':') ||
        target.startsWith('/') ||
        target.contains(r'\') ||
        target.contains(r'$')) {
      problems.add('"$written" does not apply a literal relative path');
      continue;
    }
    final parts = path.split('/')..removeLast();
    var escaped = false;
    for (final segment in target.split('/')) {
      if (segment.isEmpty || segment == '.') continue;
      if (segment != '..') {
        parts.add(segment);
      } else if (parts.isEmpty) {
        escaped = true;
      } else {
        parts.removeLast();
      }
    }
    final resolved = parts.join('/');
    if (escaped ||
        !(resolved.startsWith('android/') ||
            resolved.startsWith('third_party/'))) {
      problems.add('"$written" applies $resolved, which is outside android/ '
          'and third_party/');
    }
  }
  return problems;
}

/// Every `maven { }` / `maven(...)` in a scanned Gradle file: the call as
/// written, and the literal URLs in it.
List<(String, List<String>)> _mavenRepositories(GradleText text) => [
      for (final match
          in RegExp(r'(?<![A-Za-z0-9_])maven\s*[({]').allMatches(text.masked))
        () {
          var j = match.end - 1;
          while (j < text.masked.length &&
              (text.masked[j] == '(' || text.masked[j] == '{')) {
            j = _closingBracket(text.masked, j) + 1;
            while (j < text.masked.length &&
                (text.masked[j] == ' ' || text.masked[j] == '\t')) {
              j++;
            }
          }
          final body = text.code.substring(match.start, j).trim();
          return (
            body,
            [
              for (final url
                  in RegExp(r'''["']([A-Za-z][A-Za-z0-9+.\-]*:[^"']*)["']''')
                      .allMatches(body))
                url.group(1)!,
            ],
          );
        }(),
    ];

/// The literal URL of every Maven repository a Gradle file declares.
List<String> mavenRepositoryUrls(String source) => [
      for (final (_, urls) in _mavenRepositories(scanGradle(source))) ...urls,
    ];

/// Maven repositories the build may use besides `google()`, `mavenCentral()`
/// and `gradlePluginPortal()`, by URL, each with the reason.
const allowedMavenRepositories = <String, String>{
  'https://storage.googleapis.com/download.flutter.io':
      "Flutter's engine artifacts; the Flutter Gradle plugin adds this "
          'repository itself.',
};

const _allowedRepositoryCalls = {
  'google',
  'mavenCentral',
  'gradlePluginPortal'
};

/// Problems with the repositories a Gradle file declares: every entry of a
/// `repositories { }` block must be `google()`, `mavenCentral()`,
/// `gradlePluginPortal()` or `maven`, and every `maven { }` / `maven(...)`
/// anywhere must name only [allowedMavenRepositories] URLs, as literals.
List<String> repositoryViolations(String source) {
  final text = scanGradle(source);
  final code = text.code;
  final masked = text.masked;
  final problems = <String>[];

  int skipBlanks(int i, int end) {
    while (i < end && (masked[i] == ' ' || masked[i] == '\t')) {
      i++;
    }
    return i;
  }

  for (final (start, end) in _blockBodies(masked, 'repositories')) {
    var i = start;
    while (i < end) {
      final c = masked[i];
      if ('({['.contains(c)) {
        i = _closingBracket(masked, i) + 1;
        continue;
      }
      final word = RegExp(r'[A-Za-z_][A-Za-z0-9_.]*').matchAsPrefix(masked, i);
      if (word == null) {
        i++;
        continue;
      }
      var j = skipBlanks(word.end, end);
      while (j < end && (masked[j] == '(' || masked[j] == '{')) {
        j = skipBlanks(_closingBracket(masked, j) + 1, end);
      }
      final name = word.group(0)!;
      if (!_allowedRepositoryCalls.contains(name) && name != 'maven') {
        problems.add('repository "${code.substring(i, j).trim()}" is not '
            'google(), mavenCentral(), gradlePluginPortal() or maven');
      }
      i = j > word.end ? j : word.end;
    }
  }

  for (final (body, urls) in _mavenRepositories(text)) {
    if (urls.isEmpty) {
      problems.add('"$body" has no literal repository URL');
    }
    for (final url in urls) {
      if (!allowedMavenRepositories.containsKey(url)) {
        problems.add('maven repository "$url" is not on '
            'allowedMavenRepositories');
      }
    }
  }
  return problems;
}

/// The entries of a Gradle version catalog (`*.versions.toml`).
class VersionCatalog {
  /// Library alias → `group:artifact`, or `null` when the entry has neither a
  /// `module`, a `group` + `name`, nor a coordinate string.
  final Map<String, String?> libraries = {};

  /// Plugin alias → plugin id, or `null` when unreadable.
  final Map<String, String?> plugins = {};

  final Set<String> bundles = {};
  final Set<String> versions = {};
}

/// Parses the one-line entries of a version catalog. TOML inline tables are
/// single-line by definition; only `[bundles]` arrays may continue, and only
/// their aliases are needed.
VersionCatalog parseVersionCatalog(List<String> lines) {
  final catalog = VersionCatalog();
  String? section;
  String? quoted(String value, String key) =>
      RegExp('\\b${RegExp.escape(key)}\\s*=\\s*"([^"]*)"')
          .firstMatch(value)
          ?.group(1);
  for (final line in lines) {
    final header = RegExp(r'^\s*\[([A-Za-z]+)\]\s*$').firstMatch(line);
    if (header != null) {
      section = header.group(1);
      continue;
    }
    final entry = RegExp(r'''^\s*["']?([A-Za-z0-9_.\-]+)["']?\s*=\s*(.*)$''')
        .firstMatch(line);
    if (entry == null) continue;
    final alias = entry.group(1)!;
    final value = entry.group(2)!.trim();
    final plain = RegExp(r'^"([^"]*)"').firstMatch(value)?.group(1);
    switch (section) {
      case 'libraries':
        final module = quoted(value, 'module');
        final group = quoted(value, 'group');
        final name = quoted(value, 'name');
        final parts = plain?.split(':');
        catalog.libraries[alias] = module ??
            (group != null && name != null ? '$group:$name' : null) ??
            (parts != null && parts.length >= 2
                ? '${parts[0]}:${parts[1]}'
                : null);
      case 'plugins':
        catalog.plugins[alias] = quoted(value, 'id') ?? plain?.split(':')[0];
      case 'bundles':
        catalog.bundles.add(alias);
      case 'versions':
        catalog.versions.add(alias);
    }
  }
  return catalog;
}

/// Gradle's accessor form of a catalog alias: `-` and `_` become `.`.
String _accessor(String alias) =>
    alias.replaceAll(RegExp(r'[-_]'), '.').toLowerCase();

/// Whether `libs.[reference]` names an entry of one of [catalogs].
bool resolvesInCatalog(String reference, Iterable<VersionCatalog> catalogs) {
  final ref = reference.toLowerCase();
  for (final catalog in catalogs) {
    Iterable<String> aliases;
    String rest;
    if (ref.startsWith('plugins.')) {
      aliases = catalog.plugins.keys;
      rest = ref.substring('plugins.'.length);
    } else if (ref.startsWith('bundles.')) {
      aliases = catalog.bundles;
      rest = ref.substring('bundles.'.length);
    } else if (ref.startsWith('versions.')) {
      aliases = catalog.versions;
      rest = ref.substring('versions.'.length);
    } else {
      aliases = catalog.libraries.keys;
      rest = ref;
    }
    if (aliases.map(_accessor).contains(rest)) return true;
  }
  return false;
}

/// Every Gradle plugin id applied in a Gradle file: `id("x")`, `id 'x'`,
/// `apply(plugin = "x")`, `apply plugin: 'x'`.
List<String> gradlePluginIds(String source) {
  final text = stripGradleComments(source);
  return [
    for (final pattern in [
      RegExp(r'''(?<![A-Za-z0-9_.])id\s*\(?\s*["']([^"']+)["']'''),
      RegExp(r'''(?<![A-Za-z0-9_.])plugin\s*[:=]\s*["']([^"']+)["']'''),
    ])
      for (final match in pattern.allMatches(text)) match.group(1)!,
  ];
}

/// Paths in [paths] that are a Firebase configuration file. Its presence means
/// the Google Services plugin, and so Firebase, is being wired in.
List<String> firebaseConfigFiles(Iterable<String> paths) => [
      for (final path in paths)
        if (const ['google-services.json', 'GoogleService-Info.plist']
            .contains(path.split(RegExp(r'[/\\]')).last))
          path,
    ];

// --- Web -------------------------------------------------------------------

/// The `src` of every `<script>` tag in an HTML file, outside comments;
/// `<inline script>` for a tag without one.
List<String> webScriptSources(String html) {
  final text = html.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
  final src = RegExp(
    r'''\bsrc\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))''',
    caseSensitive: false,
  );
  return [
    for (final tag
        in RegExp(r'<script\b([^>]*)>', caseSensitive: false).allMatches(text))
      () {
        final found = src.firstMatch(tag.group(1)!);
        return found == null
            ? '<inline script>'
            : (found.group(1) ?? found.group(2) ?? found.group(3))!;
      }(),
  ];
}

// --- The real tree ---------------------------------------------------------

/// Files under [root] whose name satisfies [test], skipping build output and
/// Gradle caches. Empty when [root] does not exist.
List<File> _filesUnder(String root, bool Function(String name) test) {
  final dir = Directory(root);
  if (!dir.existsSync()) return const [];
  return [
    for (final entity in dir.listSync(recursive: true, followLinks: false))
      if (entity is File &&
          !entity.uri.pathSegments
              .any((s) => s == 'build' || s == '.gradle' || s == '.cxx') &&
          test(entity.uri.pathSegments.last))
        entity,
  ];
}

const _swiftResolvedPaths = [
  'ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved',
  'ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/'
      'Package.resolved',
];

void main() {
  late List<LockedPackage> locked;
  late Map<String, String> gradleFiles;
  late Map<String, VersionCatalog> catalogs;
  late Map<String, List<String>> gradleCoordinates;
  late List<String> nativeCoordinates;
  late List<String> repositoryUrls;
  late List<String> pluginIds;
  late String pbxproj;
  late List<String> remoteSwiftPackages;
  late List<String> swiftManifestUrlsFound;
  late List<String> webScripts;

  setUpAll(() {
    final lock = File('pubspec.lock');
    expect(lock.existsSync(), isTrue, reason: 'pubspec.lock is missing');
    locked = parseLock(lock.readAsLinesSync());

    gradleFiles = {
      for (final root in ['android', 'third_party'])
        for (final file in _filesUnder(root,
            (name) => name.endsWith('.gradle') || name.endsWith('.gradle.kts')))
          file.path: file.readAsStringSync(),
    };
    catalogs = {
      for (final root in ['android/gradle', 'gradle'])
        for (final file
            in _filesUnder(root, (name) => name.endsWith('.versions.toml')))
          file.path: parseVersionCatalog(file.readAsLinesSync()),
    };
    gradleCoordinates = {
      for (final MapEntry(key: path, value: source) in gradleFiles.entries)
        path: gradleFileCoordinates(source),
    };
    nativeCoordinates = [
      for (final coordinates in gradleCoordinates.values) ...coordinates,
      for (final catalog in catalogs.values)
        ...catalog.libraries.values.whereType<String>(),
    ];
    repositoryUrls = [
      for (final source in gradleFiles.values) ...mavenRepositoryUrls(source),
    ];
    pluginIds = [
      for (final source in gradleFiles.values) ...gradlePluginIds(source),
      for (final catalog in catalogs.values)
        ...catalog.plugins.values.whereType<String>(),
    ];

    pbxproj = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    remoteSwiftPackages = pbxprojObjectField(pbxproj,
        isa: 'XCRemoteSwiftPackageReference', field: 'repositoryURL');
    swiftManifestUrlsFound = [
      for (final file
          in _filesUnder('third_party', (n) => n == 'Package.swift'))
        ...swiftManifestUrls(file.readAsStringSync()),
    ];
    webScripts = webScriptSources(File('web/index.html').readAsStringSync());
  });

  test('every direct runtime dependency in pubspec.lock is allowlisted', () {
    final direct = directRuntimeDependencies(locked);
    expect(direct, contains('flutter'),
        reason: 'pubspec.lock was not parsed: no direct main "flutter"');

    expect(
      direct.where((name) => !allowedRuntimePackages.containsKey(name)),
      isEmpty,
      reason: 'a runtime package appeared that is not on the allowlist at the '
          'top of this test. Adding one is a decision about what leaves a '
          'patient device — add it there, with the reason, or remove it here.',
    );
  });

  test('pubspec.yaml runtime dependencies are allowlisted too', () {
    final names = runtimeDependencyNames(
      File('pubspec.yaml').readAsLinesSync(),
    );
    expect(names, contains('flutter'),
        reason: 'pubspec dependencies block was not found or not parsed');

    expect(
      names.where((name) => !allowedRuntimePackages.containsKey(name)),
      isEmpty,
      reason: 'pubspec.yaml declares a runtime package that is not on the '
          'allowlist at the top of this test.',
    );
  });

  test('every allowlist entry carries a one-line reason', () {
    for (final allowlist in [
      allowedRuntimePackages,
      allowedNativeDependencies,
      allowedGradlePlugins,
      allowedMavenRepositories,
      allowedSwiftPackageUrls,
      allowedLocalSwiftPackages,
      allowedWebScripts,
    ]) {
      for (final entry in allowlist.entries) {
        expect(entry.value.trim(), isNotEmpty,
            reason: '${entry.key} has no reason');
        expect(entry.value.contains('\n'), isFalse,
            reason: '${entry.key} reason is more than one line');
      }
    }
  });

  test('no present dependency is still allowlisted "review pending"', () {
    final present = <String, (Map<String, String>, Iterable<String>)>{
      'allowedRuntimePackages': (
        allowedRuntimePackages,
        [
          ...directRuntimeDependencies(locked),
          ...runtimeDependencyNames(File('pubspec.yaml').readAsLinesSync()),
        ],
      ),
      'allowedNativeDependencies': (
        allowedNativeDependencies,
        nativeCoordinates
      ),
      'allowedGradlePlugins': (allowedGradlePlugins, pluginIds),
      'allowedMavenRepositories': (allowedMavenRepositories, repositoryUrls),
      'allowedSwiftPackageUrls': (
        allowedSwiftPackageUrls,
        [...remoteSwiftPackages, ...swiftManifestUrlsFound],
      ),
      'allowedLocalSwiftPackages': (
        allowedLocalSwiftPackages,
        pbxprojObjectField(pbxproj,
            isa: 'XCLocalSwiftPackageReference', field: 'relativePath'),
      ),
      'allowedWebScripts': (allowedWebScripts, webScripts),
    };
    for (final MapEntry(key: name, value: (allowlist, names))
        in present.entries) {
      expect(
        presentButPendingReview(allowlist, names),
        isEmpty,
        reason: 'these are dependencies now, but their $name reason still '
            'says the review is pending. Replace it with what was reviewed '
            '(and by whom) before the dependency lands.',
      );
    }
  });

  test('every locked package comes from pub.dev, the SDK or third_party/', () {
    expect(locked, isNotEmpty, reason: 'pubspec.lock lists no packages');
    for (final package in locked) {
      expect(
        sourceViolation(package),
        isNull,
        reason: 'pubspec.lock: ${package.name} — ${sourceViolation(package)}.',
      );
    }
  });

  test('nothing overrides the resolved dependencies', () {
    expect(
      hasDependencyOverrides(File('pubspec.yaml').readAsLinesSync()),
      isFalse,
      reason: 'pubspec.yaml has a dependency_overrides block, which can swap '
          'an allowlisted package for code from anywhere.',
    );
    expect(
      File('pubspec_overrides.yaml').existsSync(),
      isFalse,
      reason: 'pubspec_overrides.yaml overrides dependencies outside '
          'pubspec.yaml.',
    );
  });

  test('analytics, ads and crash SDKs stay forbidden, allowlist or not', () {
    final podfileLock = File('ios/Podfile.lock');
    final sources = <String, Iterable<String>>{
      'the allowlists in this test': [
        ...allowedRuntimePackages.keys,
        ...allowedNativeDependencies.keys,
        ...allowedGradlePlugins.keys,
        ...allowedMavenRepositories.keys,
        ...allowedSwiftPackageUrls.keys,
        ...allowedLocalSwiftPackages.keys,
        ...allowedWebScripts.keys,
      ],
      'pubspec.yaml dependencies': runtimeDependencyNames(
        File('pubspec.yaml').readAsLinesSync(),
      ),
      'pubspec.lock': locked.map((package) => package.name),
      'Gradle files and version catalogs': nativeCoordinates,
      'Gradle plugins': pluginIds,
      'Gradle maven repositories': repositoryUrls,
      'ios/Runner.xcodeproj/project.pbxproj Swift packages':
          remoteSwiftPackages,
      'third_party Package.swift URLs': swiftManifestUrlsFound,
      'web/index.html scripts': webScripts,
      if (podfileLock.existsSync())
        'ios/Podfile.lock': podNames(podfileLock.readAsLinesSync()),
      for (final path in _swiftResolvedPaths)
        if (File(path).existsSync())
          path: swiftResolvedPins(File(path).readAsStringSync()) ??
              (throw TestFailure('$path is not a readable Package.resolved')),
    };

    final offenders = [
      for (final source in sources.entries)
        for (final name in source.value)
          if (forbiddenFamilyOf(name) case final family?)
            '${source.key} contains "$name" ("$family" family)',
    ];
    expect(offenders.toSet().toList(), isEmpty, reason: _rule);
  });

  test('no forbidden SDK appears anywhere in the build configuration', () {
    final files = <String>[
      'pubspec.yaml',
      'pubspec.lock',
      'android/app/build.gradle.kts',
      'android/build.gradle.kts',
      'android/settings.gradle.kts',
      'android/gradle/libs.versions.toml',
      'android/app/src/main/AndroidManifest.xml',
      'ios/Runner/Info.plist',
      'web/index.html',
      // Every Gradle file and version catalog found, the vendored
      // third_party/ Groovy builds included.
      ...gradleFiles.keys,
      ...catalogs.keys,
    ];

    final offenders = <String>[];
    for (final path in files.toSet()) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final contents = file.readAsStringSync().toLowerCase();
      for (final fragment in forbiddenFamilies) {
        // Bounded by anything that is not a letter or digit, so `_`, `.` and
        // `-` count as boundaries (`firebase_core`, `com.google.firebase`)
        // while `windowSoftInputMode="adjustResize"` is not mistaken for the
        // Adjust SDK.
        if (RegExp('(?<![a-z0-9])$fragment(?![a-z0-9])').hasMatch(contents)) {
          offenders.add('$path mentions "$fragment"');
        }
      }
    }
    expect(offenders, isEmpty, reason: _rule);
  });

  test('every Android dependency, in any configuration, is allowlisted', () {
    expect(gradleFiles.keys, contains('android/app/build.gradle.kts'),
        reason: 'the Gradle files were not found');
    expect(nativeCoordinates, contains('org.jetbrains.kotlin:kotlin-stdlib'),
        reason: 'the Gradle scan did not see the vendored flutter_tts '
            'kotlin-stdlib dependency, so it is not reading the files');

    final offenders = <String>[
      for (final MapEntry(key: path, value: source) in gradleFiles.entries) ...[
        for (final dep in gradleCoordinates[path]!)
          if (!allowedNativeDependencies.containsKey(dep))
            '$path: $dep is not on allowedNativeDependencies',
        for (final declaration in gradleDeclarations(source))
          if (unrecognisedNotation(declaration) case final problem?)
            '$path: $problem',
        for (final reference in libsReferences(source))
          if (!resolvesInCatalog(reference, catalogs.values))
            '$path: libs.$reference is not an entry of any version catalog '
                'in android/gradle/ or gradle/',
      ],
      for (final MapEntry(key: path, value: catalog) in catalogs.entries) ...[
        for (final MapEntry(key: alias, value: module)
            in catalog.libraries.entries)
          if (module == null)
            '$path: library "$alias" has no readable module'
          else if (!allowedNativeDependencies.containsKey(module))
            '$path: library "$alias" ($module) is not on '
                'allowedNativeDependencies',
        for (final MapEntry(key: alias, value: id) in catalog.plugins.entries)
          if (id == null) '$path: plugin "$alias" has no readable id',
      ],
    ];
    expect(
      offenders.toSet().toList(),
      isEmpty,
      reason: 'Adding an Android dependency (any configuration, platform(...), '
          'classpath or version-catalog entry) is a decision about what ships '
          '— add it to allowedNativeDependencies with the reason, or remove '
          'it. Declare it as a quoted group:artifact:version, map notation '
          'with literal group and name, or a version-catalog entry, so this '
          'test can see it.',
    );
  });

  test('Gradle fetches only from allowlisted repositories and scripts', () {
    final offenders = <String>[
      for (final MapEntry(key: path, value: source) in gradleFiles.entries) ...[
        for (final problem in repositoryViolations(source)) '$path: $problem',
        for (final problem in applyFromViolations(path, source))
          '$path: $problem',
      ],
    ];
    expect(
      offenders,
      isEmpty,
      reason: 'Gradle may resolve from google(), mavenCentral(), '
          'gradlePluginPortal() and allowedMavenRepositories only, and apply '
          'only scripts inside android/ or third_party/: another repository '
          'or a remote script can supply code no allowlist here sees.',
    );
  });

  test('every Gradle plugin is allowlisted', () {
    expect(pluginIds, contains('com.android.application'),
        reason: 'the Gradle plugin scan found nothing');
    expect(
      pluginIds.where((id) => !allowedGradlePlugins.containsKey(id)).toSet(),
      isEmpty,
      reason: 'a Gradle plugin is applied that is not on allowedGradlePlugins '
          '(com.google.gms.google-services, for one, wires in Firebase).',
    );
  });

  test('no Firebase configuration file is in the project', () {
    final found = firebaseConfigFiles([
      for (final root in ['android', 'ios'])
        for (final file in _filesUnder(root, (_) => true)) file.path,
    ]);
    expect(found, isEmpty,
        reason: 'a google-services.json / GoogleService-Info.plist is a '
            'Firebase project configuration. $_rule');
  });

  test('the iOS project references no Swift package outside the allowlist', () {
    final local = pbxprojObjectField(pbxproj,
        isa: 'XCLocalSwiftPackageReference', field: 'relativePath');
    expect(
      local,
      contains('Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage'),
      reason: 'project.pbxproj was not parsed: Flutter\'s generated local '
          'Swift package reference was not found',
    );
    expect(
      local.where((path) => !allowedLocalSwiftPackages.containsKey(path)),
      isEmpty,
      reason: 'project.pbxproj references a local Swift package that is not '
          'on allowedLocalSwiftPackages.',
    );
    expect(
      remoteSwiftPackages
          .where((url) => !allowedSwiftPackageUrls.containsKey(url)),
      isEmpty,
      reason: 'project.pbxproj has an XCRemoteSwiftPackageReference that is '
          'not on allowedSwiftPackageUrls. Adding one is a decision about '
          'what ships — add it there, with the reason, or remove it.',
    );
    expect(
      swiftManifestUrlsFound
          .where((url) => !allowedSwiftPackageUrls.containsKey(url)),
      isEmpty,
      reason: 'a vendored Package.swift under third_party/ fetches a remote '
          'package or binary that is not on allowedSwiftPackageUrls.',
    );
  });

  test('iOS stays Swift Package Manager only: no Podfile, no pods', () {
    // tool/build_ios_release.sh refuses CocoaPods (an ios/Podfile, and Pods
    // references in project.pbxproj or the xcconfigs) before a release build;
    // those references are left to it. CI's `flutter build ios` does not run
    // that script, so the files that pull pods in are refused here as well.
    final podfileLock = File('ios/Podfile.lock');
    if (podfileLock.existsSync()) {
      fail('ios/Podfile.lock exists (pods: '
          '${podNames(podfileLock.readAsLinesSync()).join(', ')}). This '
          'project uses Swift Package Manager only; remove it and ios/Podfile '
          '(do not commit them). Any forbidden pod among them is named by the '
          '"stay forbidden" test above.');
    }
    expect(File('ios/Podfile').existsSync(), isFalse,
        reason: 'ios/Podfile exists; this project uses Swift Package Manager '
            'only. Remove it (do not commit it). If `flutter pub get` created '
            'it, Swift Package Manager is switched off in your Flutter config.');
  });

  test('web/index.html loads only allowlisted scripts', () {
    expect(webScripts, contains('flutter_bootstrap.js'),
        reason: 'web/index.html was not parsed: no flutter_bootstrap.js');
    expect(
      webScripts.where((src) => !allowedWebScripts.containsKey(src)),
      isEmpty,
      reason: 'web/index.html loads a script that is not on allowedWebScripts '
          '(an inline script counts). Tag managers and analytics snippets '
          'arrive this way.',
    );
  });

  group('self-check: the guard catches what it claims to', () {
    test('forbidden families are recognised by name', () {
      for (final name in [
        'firebase_core',
        'firebase_analytics',
        'firebase_crashlytics',
        'sentry_flutter',
        'amplitude_flutter',
        'mixpanel_flutter',
        'segment_analytics',
        'appsflyer_sdk',
        'facebook_app_events',
        'flutter_facebook_auth',
        'google_mobile_ads',
        'flutter_branch_sdk',
        'purchases_flutter',
        'launchdarkly_flutter_client_sdk',
        'rollbar_flutter',
        'statsig',
        'appmetrica_plugin',
        'agconnect_core',
        // Added in TH-992.
        'customer_io',
        'raygun4flutter',
        'opentelemetry',
        'contentsquare',
        'glassbox_flutter',
        'userexperior',
        'user_experior',
        'quantum_metric_flutter',
      ]) {
        expect(forbiddenFamilyOf(name), isNotNull, reason: name);
      }
    });

    test('native names are recognised by word, camelCase and joined words', () {
      for (final name in [
        'FirebaseAnalytics',
        'Firebase/CoreOnly',
        'GoogleAppMeasurement',
        'AppsFlyerFramework',
        'FBSDKCoreKit',
        'Sentry',
        'NewRelicAgent',
        'LaunchDarkly',
        'ContentsquareModule',
        'QuantumMetricSDK',
        'UXCam',
        'com.google.firebase:firebase-bom',
        'io.sentry:sentry-android',
        'com.raygun:raygun4android',
        'io.opentelemetry:opentelemetry-api',
        'com.google.gms:play-services-ads',
        'https://github.com/firebase/firebase-ios-sdk',
        'https://cdn.example/analytics.js',
        // Added in TH-992 round 1.
        'com.google.android.gms:play-services-measurement-api',
        'com.google.android.datatransport:transport-runtime',
        'GoogleDataTransport',
      ]) {
        expect(forbiddenFamilyOf(name), isNotNull, reason: name);
      }
      for (final name in [
        'GoogleSignIn',
        'GTMSessionFetcher',
        'AppAuth',
        'GTMAppAuth',
        'AppCheckCore',
        'GoogleUtilities',
        'androidx.health.connect:connect-client',
        'com.google.android.gms:play-services-auth',
        'androidx.credentials:credentials',
        'org.jetbrains.kotlin:kotlin-stdlib',
        'flutter_bootstrap.js',
        'windowSoftInputMode',
      ]) {
        expect(forbiddenFamilyOf(name), isNull, reason: name);
      }
    });

    test('every allowlisted name passes the denylist', () {
      for (final name in [
        ...allowedRuntimePackages.keys,
        ...allowedNativeDependencies.keys,
        ...allowedGradlePlugins.keys,
        ...allowedMavenRepositories.keys,
        ...allowedSwiftPackageUrls.keys,
        ...allowedLocalSwiftPackages.keys,
        ...allowedWebScripts.keys,
      ]) {
        expect(forbiddenFamilyOf(name), isNull, reason: name);
      }
    });

    test('a present dependency still "review pending" is caught', () {
      const allowlist = {
        'present_pending': 'Owner decision; th-security review pending (TH-1)',
        'present_reviewed': 'Reviewed by th-security on 2026-10-18 (TH-1).',
        'absent_pending': 'Owner decision; review pending (TH-2)',
        'present_pending_other_wording': 'Pending Review by th-security.',
      };
      expect(
        presentButPendingReview(allowlist, [
          'present_pending',
          'present_reviewed',
          'present_pending_other_wording',
          'not_allowlisted',
        ]),
        ['present_pending', 'present_pending_other_wording'],
      );
      expect(presentButPendingReview(allowlist, const []), isEmpty);
    });

    test('dev_dependencies are not read as runtime dependencies', () {
      const pubspec = '''
name: synthetic_app
dependencies:
  flutter:
    sdk: flutter
  # a comment
  local_pkg:
    path: third_party/local_pkg
  firebase_core: ^3.0.0

dev_dependencies:
  sentry_flutter: ^8.0.0
''';
      final names = runtimeDependencyNames(pubspec.split('\n'));
      expect(names, ['flutter', 'local_pkg', 'firebase_core']);
      expect(
        names.where((name) => !allowedRuntimePackages.containsKey(name)),
        ['local_pkg', 'firebase_core'],
      );
      expect(names.map(forbiddenFamilyOf).whereType<String>(), ['firebase']);
    });

    test('quoted keys, spaced colons and overrides are caught', () {
      const pubspec = '''
"dependencies" :
  flutter:
    sdk: flutter
  "collection": ^1.18.0
  'meta' : ^1.9.0
dependency_overrides:
  http: ^1.0.0
''';
      final lines = pubspec.split('\n');
      final names = runtimeDependencyNames(lines);
      expect(names, ['flutter', 'collection', 'meta']);
      expect(
        names.where((name) => !allowedRuntimePackages.containsKey(name)),
        ['collection', 'meta'],
      );
      expect(hasDependencyOverrides(lines), isTrue);
      expect(
          hasDependencyOverrides(['dependencies:', '  http: ^1.0.0']), isFalse);
    });

    test('lock parsing finds direct deps and rejects foreign sources', () {
      const lock = '''
# Generated by pub
packages:
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
  http:
    dependency: "direct overridden"
    description:
      name: http
      sha256: aa
      url: "https://pub.dev"
    source: hosted
    version: "1.6.0"
  vendored:
    dependency: transitive
    description:
      path: "third_party/vendored"
      relative: true
    source: path
    version: "1.0.0"
  from_git:
    dependency: "direct main"
    description:
      path: "."
      ref: main
      resolved-ref: bb
      url: "https://github.com/example/from_git.git"
    source: git
    version: "1.0.0"
  other_host:
    dependency: transitive
    description:
      name: other_host
      sha256: cc
      url: "https://pub.example.test"
    source: hosted
    version: "1.0.0"
  escaped_path:
    dependency: transitive
    description:
      path: "third_party/../../elsewhere"
      relative: true
    source: path
    version: "1.0.0"
  absolute_path:
    dependency: transitive
    description:
      path: "/tmp/elsewhere"
      relative: false
    source: path
    version: "1.0.0"
sdks:
  dart: ">=3.4.0 <4.0.0"
''';
      final packages = parseLock(lock.split('\n'));
      expect(packages.map((package) => package.name), [
        'flutter',
        'http',
        'vendored',
        'from_git',
        'other_host',
        'escaped_path',
        'absolute_path',
      ]);
      expect(
          directRuntimeDependencies(packages), ['flutter', 'http', 'from_git']);
      expect(
        packages
            .where((package) => sourceViolation(package) != null)
            .map((package) => package.name),
        ['from_git', 'other_host', 'escaped_path', 'absolute_path'],
      );
    });

    test('pbxproj Swift package references are read, compact or not', () {
      const pbxproj = '''
/* Begin XCLocalSwiftPackageReference section */
		A1 /* XCLocalSwiftPackageReference "FlutterGeneratedPluginSwiftPackage" */ = {
			isa = XCLocalSwiftPackageReference;
			relativePath = Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage;
		};
		A2 /* XCLocalSwiftPackageReference "Vendored" */ = {
			isa = XCLocalSwiftPackageReference;
			relativePath = "../vendor/SomeSDK";
		};
/* End XCLocalSwiftPackageReference section */
/* Begin XCRemoteSwiftPackageReference section */
		B1 /* XCRemoteSwiftPackageReference "firebase-ios-sdk" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/firebase/firebase-ios-sdk";
			requirement = {
				kind = upToNextMajorVersion;
				minimumVersion = 11.0.0;
			};
		};
		B2 = {isa = "XCRemoteSwiftPackageReference"; repositoryURL = https://example.test/pkg.git; };
		B3 /* no URL */ = {
			isa = XCRemoteSwiftPackageReference;
		};
		C1 = {
			isa = XCSwiftPackageProductDependency;
			productName = FirebaseAnalytics;
		};
/* End XCRemoteSwiftPackageReference section */
''';
      final remote = pbxprojObjectField(pbxproj,
          isa: 'XCRemoteSwiftPackageReference', field: 'repositoryURL');
      expect(remote, [
        'https://github.com/firebase/firebase-ios-sdk',
        'https://example.test/pkg.git',
        '<no repositoryURL>',
      ]);
      expect(remote.where((url) => !allowedSwiftPackageUrls.containsKey(url)),
          hasLength(3));
      final local = pbxprojObjectField(pbxproj,
          isa: 'XCLocalSwiftPackageReference', field: 'relativePath');
      expect(local, [
        'Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage',
        '../vendor/SomeSDK',
      ]);
      expect(
        local.where((path) => !allowedLocalSwiftPackages.containsKey(path)),
        ['../vendor/SomeSDK'],
      );
    });

    test('Package.swift URLs and Package.resolved pins are read', () {
      const manifest = '''
let package = Package(
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.0.0"),
    ],
    targets: [
        .binaryTarget(name: "Blob", url: "https://cdn.example/Blob.zip", checksum: "00"),
    ]
)
''';
      expect(swiftManifestUrls(manifest), [
        'https://github.com/getsentry/sentry-cocoa',
        'https://cdn.example/Blob.zip',
      ]);

      const v2 = '{"pins": [{"identity": "firebase-ios-sdk", "kind": '
          '"remoteSourceControl", "location": '
          '"https://github.com/firebase/firebase-ios-sdk"}], "version": 2}';
      const v1 = '{"object": {"pins": [{"package": "GoogleSignIn", '
          '"repositoryURL": "https://github.com/google/GoogleSignIn-iOS"}]}, '
          '"version": 1}';
      expect(swiftResolvedPins(v2), [
        'firebase-ios-sdk',
        'https://github.com/firebase/firebase-ios-sdk',
      ]);
      expect(swiftResolvedPins(v2)!.map(forbiddenFamilyOf).whereType<String>(),
          isNotEmpty);
      expect(swiftResolvedPins(v1), [
        'GoogleSignIn',
        'https://github.com/google/GoogleSignIn-iOS',
      ]);
      expect(swiftResolvedPins('not json'), isNull);
      expect(swiftResolvedPins('{"version": 2}'), isNull);
    });

    test('Podfile.lock pod names are read, subspecs and nesting included', () {
      const podfileLock = '''
PODS:
  - Firebase/Analytics (11.0.0):
    - Firebase/Core
  - "FirebaseAnalytics (11.0.0)":
    - GoogleAppMeasurement (= 11.0.0)
  - Flutter (1.0.0)

DEPENDENCIES:
  - Flutter (from `Flutter`)

SPEC CHECKSUMS:
  Flutter: 00
  "Sentry": 11

PODFILE CHECKSUM: 22

COCOAPODS: 1.16.2
''';
      final pods = podNames(podfileLock.split('\n'));
      expect(pods, [
        'Firebase/Analytics',
        'Firebase/Core',
        'FirebaseAnalytics',
        'GoogleAppMeasurement',
        'Flutter',
        'Sentry',
      ]);
      expect(pods.where((pod) => forbiddenFamilyOf(pod) == null), ['Flutter']);
    });

    test('Gradle declarations in every configuration are read', () {
      const kts = '''
plugins {
    id("com.android.application")
    id("com.google.gms.google-services") version "4.4.2" apply false
    alias(libs.plugins.kotlin.android)
}
// implementation("commented.out:in-a-comment:1.0") is prose
/* api("also.commented:out:1.0") */
dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    api("com.google.firebase:firebase-analytics:22.0.0")
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    runtimeOnly("io.sentry:sentry-android:7.0.0")
    compileOnly("com.example:compile-only:1.0")
    kapt("com.example:kapt-processor:1.0")
    ksp("com.example:ksp-processor:1.0")
    debugImplementation("com.example:debug-only:1.0")
    testImplementation("junit:junit:4.13.2")
    implementation(libs.firebase.messaging)
    implementation(files("libs/vendor-sdk.aar"))
    implementation(fileTree("libs"))
    implementation(project(":vendor"))
    implementation(vendorSdk)
}
''';
      // Raw text: the commented-out coordinates count too (fail closed).
      expect(mavenCoordinates(kts), [
        'commented.out:in-a-comment',
        'also.commented:out',
        'org.jetbrains.kotlinx:kotlinx-coroutines-android',
        'com.google.firebase:firebase-analytics',
        'com.google.firebase:firebase-bom',
        'io.sentry:sentry-android',
        'com.example:compile-only',
        'com.example:kapt-processor',
        'com.example:ksp-processor',
        'com.example:debug-only',
        'junit:junit',
      ]);
      final declarations = gradleDeclarations(kts);
      expect(declarations.map((d) => d.configuration), [
        'implementation',
        'api',
        'implementation',
        'runtimeOnly',
        'compileOnly',
        'kapt',
        'ksp',
        'debugImplementation',
        'testImplementation',
        'implementation',
        'implementation',
        'implementation',
        'implementation',
        'implementation',
      ]);
      expect(
        declarations
            .where((d) => unrecognisedNotation(d) != null)
            .map((d) => d.notation),
        [
          'files("libs/vendor-sdk.aar")',
          'fileTree("libs")',
          'project(":vendor")',
          'vendorSdk',
        ],
      );
      expect(libsReferences(kts),
          ['plugins.kotlin.android', 'firebase.messaging']);
      expect(gradlePluginIds(kts),
          ['com.android.application', 'com.google.gms.google-services']);
      expect(
        gradlePluginIds(kts)
            .where((id) => !allowedGradlePlugins.containsKey(id)),
        ['com.google.gms.google-services'],
      );
      expect(
        mavenCoordinates(kts)
            .where((dep) => !allowedNativeDependencies.containsKey(dep)),
        hasLength(10),
      );
    });

    test('Groovy declarations and plugins are read; prose is not', () {
      const groovy = '''
def args = ["-Xlint:deprecation"]
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.2'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:\$kotlin_version"
    }
}
apply plugin: 'com.android.library'
apply plugin: 'com.google.gms.google-services'
android {
    compileSdk 36
    defaultConfig {
        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
    }
}
dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib:\$kotlin_version"
    api platform('com.google.firebase:firebase-bom:33.0.0')
    runtimeOnly libs.sentry
    implementation files('libs/vendor.jar')
}
''';
      expect(mavenCoordinates(groovy), [
        'com.google.gms:google-services',
        'org.jetbrains.kotlin:kotlin-gradle-plugin',
        'org.jetbrains.kotlin:kotlin-stdlib',
        'com.google.firebase:firebase-bom',
      ]);
      expect(gradleDeclarations(groovy).map((d) => d.toString()), [
        "classpath('com.google.gms:google-services:4.4.2')",
        'classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:\$kotlin_version")',
        'implementation("org.jetbrains.kotlin:kotlin-stdlib:\$kotlin_version")',
        "api(platform('com.google.firebase:firebase-bom:33.0.0'))",
        'runtimeOnly(libs.sentry)',
        "implementation(files('libs/vendor.jar'))",
      ]);
      expect(gradlePluginIds(groovy),
          ['com.android.library', 'com.google.gms.google-services']);
    });

    test('the Gradle scanner is string-aware', () {
      const kts = """
android {
    packaging { resources { excludes += "**/*.so" } }
}
dependencies {
    implementation("com.example:between-globs:1.0")
}
val other = "**/*.txt"
val path = "a//b" // a real comment
val raw = \"\"\"has // and /* inside\"\"\"
dependencies { api("com.example:after-raw:1.0") }
/* api("com.example:in-block-comment:1.0") */
""";
      expect(
        gradleDeclarations(kts).map((d) => d.toString()),
        [
          'implementation("com.example:between-globs:1.0")',
          'api("com.example:after-raw:1.0")',
        ],
      );
      final code = stripGradleComments(kts);
      expect(code, contains('"a//b"'));
      expect(code, contains('"**/*.so"'));
      expect(code, contains('has // and /* inside'));
      expect(code, isNot(contains('a real comment')));
      expect(code, isNot(contains('in-block-comment')));
      expect(code.length, kts.length);
      // Raw-text coordinates still see the commented one: fail closed.
      expect(mavenCoordinates(kts), contains('com.example:in-block-comment'));
    });

    test('Groovy no-paren declarations of every shape are read', () {
      const groovy = """
android {
    compileSdk 36
    implementation = "not a declaration outside dependencies"
}
dependencies {
    implementation group: 'com.example', name: 'map-notation', version: '1.0'
    implementation sdk
    implementation rootProject.ext.vendorSdk
    implementation /com.example:slashy:1.0/
    runtimeOnly 'com.example:quoted:1.0'
    kapt {
        arguments { arg("x", "y") }
    }
    testImplementation.extendsFrom(foo)
    implementation = files('x')
}
""";
      final declarations = gradleDeclarations(groovy);
      expect(declarations.map((d) => d.toString()), [
        "implementation(group: 'com.example', name: 'map-notation', "
            "version: '1.0')",
        'implementation(sdk)',
        'implementation(rootProject.ext.vendorSdk)',
        'implementation(/com.example:slashy:1.0/)',
        "runtimeOnly('com.example:quoted:1.0')",
      ]);
      expect(
        declarations
            .where((d) => unrecognisedNotation(d) != null)
            .map((d) => d.notation),
        [
          'sdk',
          'rootProject.ext.vendorSdk',
          '/com.example:slashy:1.0/',
        ],
      );
      expect(
        mapNotationCoordinate(declarations.first.notation),
        'com.example:map-notation',
      );
      expect(mapNotationCoordinate('group = "g", name = "a"'), 'g:a');
      expect(mapNotationCoordinate("group: g, name: 'a'"), isNull);
      expect(gradleFileCoordinates(groovy), [
        'com.example:quoted',
        'com.example:map-notation',
      ]);
    });

    test('string-invoked and add(...) declarations are read', () {
      const kts = """
val keys = buildList { add("android/key.properties not found") }
dependencies {
    "implementation"("com.example:string-invoked:1.0")
    "api"(vendorSdk)
    add("implementation", "com.example:added:1.0")
    dependencies.add("runtimeOnly", vendorSdk)
    project.dependencies.add("kapt", files("x.jar"))
    add("notAConfiguration", "com.example:ignored:1.0")
}
""";
      final declarations = gradleDeclarations(kts);
      expect(declarations.map((d) => d.toString()), [
        'implementation("com.example:string-invoked:1.0")',
        'api(vendorSdk)',
        'implementation("com.example:added:1.0")',
        'runtimeOnly(vendorSdk)',
        'kapt(files("x.jar"))',
      ]);
      expect(
        declarations
            .where((d) => unrecognisedNotation(d) != null)
            .map((d) => d.notation),
        ['vendorSdk', 'vendorSdk', 'files("x.jar")'],
      );
    });

    test('apply from: must stay a relative path inside the build', () {
      const source = """
apply from: 'flutter_tts.gradle'
apply(from = "../app/shared.gradle.kts")
apply from: "https://example.test/remote.gradle"
apply(from = "../../tool/outside.gradle")
apply from: '/etc/absolute.gradle'
apply from: rootProject.file('computed.gradle')
apply from: "\$rootDir/templated.gradle"
apply plugin: 'com.android.library'
""";
      final problems = applyFromViolations('android/app/build.gradle', source);
      expect(problems, hasLength(5));
      expect(problems[0], contains('example.test/remote.gradle'));
      expect(problems[1], contains('outside android/ and third_party/'));
      expect(problems[2], contains('/etc/absolute.gradle'));
      expect(problems[3], contains('computed.gradle'));
      expect(problems[4], contains('templated.gradle'));
      expect(
          applyFromViolations('third_party/x/android/build.gradle',
              "apply from: '../../../android/app/ok.gradle'"),
          isEmpty);
    });

    test('only allowlisted repositories pass', () {
      const source = """
pluginManagement {
    repositories {
        google {
            content { includeGroupByRegex("com\\\\.android.*") }
        }
        mavenCentral()
        gradlePluginPortal()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}
allprojects {
    repositories {
        mavenLocal()
        jcenter()
        maven { url "https://repo.example.test/maven" }
        maven(url = vendorRepo)
        flatDir { dirs("libs") }
    }
}
""";
      final problems = repositoryViolations(source);
      expect(problems, hasLength(5));
      expect(problems.where((p) => p.contains('mavenLocal()')), hasLength(1));
      expect(problems.where((p) => p.contains('jcenter()')), hasLength(1));
      expect(problems.where((p) => p.contains('flatDir')), hasLength(1));
      expect(
        problems.where((p) => p.contains('"https://repo.example.test/maven"')),
        hasLength(1),
      );
      expect(
        problems.where((p) => p.contains('maven(url = vendorRepo)')),
        hasLength(1),
      );
      expect(mavenRepositoryUrls(source), [
        'https://storage.googleapis.com/download.flutter.io',
        'https://repo.example.test/maven',
      ]);
      expect(
        repositoryViolations(
            'repositories {\n    google()\n    mavenCentral()\n}\n'),
        isEmpty,
      );
    });

    test('version catalogs are read and libs. references resolved', () {
      const toml = '''
[versions]
kotlin = "2.4.0"

[libraries]
firebase-bom = { module = "com.google.firebase:firebase-bom", version = "33.0.0" }
sentry_android = { group = "io.sentry", name = "sentry-android", version.ref = "kotlin" }
"plain.string" = "com.example:plain:1.0"
broken = { version = "1.0" }

[bundles]
tracking = [
    "firebase-bom",
    "sentry_android",
]

[plugins]
gms = { id = "com.google.gms.google-services", version = "4.4.2" }
''';
      final catalog = parseVersionCatalog(toml.split('\n'));
      expect(catalog.libraries, {
        'firebase-bom': 'com.google.firebase:firebase-bom',
        'sentry_android': 'io.sentry:sentry-android',
        'plain.string': 'com.example:plain',
        'broken': null,
      });
      expect(catalog.plugins, {'gms': 'com.google.gms.google-services'});
      expect(catalog.bundles, {'tracking'});
      expect(catalog.versions, {'kotlin'});
      expect(mavenCoordinates(toml), [
        'com.google.firebase:firebase-bom',
        'com.example:plain',
      ]);
      for (final ref in [
        'firebase.bom',
        'sentry.android',
        'plain.string',
        'bundles.tracking',
        'plugins.gms',
        'versions.kotlin',
      ]) {
        expect(resolvesInCatalog(ref, [catalog]), isTrue, reason: ref);
      }
      expect(resolvesInCatalog('firebase', [catalog]), isFalse);
      expect(resolvesInCatalog('firebase', const []), isFalse);
      expect(resolvesInCatalog('plugins.firebase.bom', [catalog]), isFalse);
    });

    test('Firebase configuration files are found by name', () {
      expect(
        firebaseConfigFiles([
          'android/app/google-services.json',
          'android/app/src/debug/google-services.json',
          r'ios\Runner\GoogleService-Info.plist',
          'android/app/src/main/AndroidManifest.xml',
          'ios/Runner/Info.plist',
          'docs/google-services.json.md',
        ]),
        [
          'android/app/google-services.json',
          'android/app/src/debug/google-services.json',
          r'ios\Runner\GoogleService-Info.plist',
        ],
      );
    });

    test('web script tags are read, inline and commented ones handled', () {
      const html = '''
<html><head>
  <!-- <script src="commented-out.js"></script> -->
  <SCRIPT src='https://cdn.example/analytics.js' async></SCRIPT>
  <script>window.dataLayer = [];</script>
  <script type="module" src=main.dart.js></script>
</head><body>
  <script src="flutter_bootstrap.js" async></script>
</body></html>
''';
      final scripts = webScriptSources(html);
      expect(scripts, [
        'https://cdn.example/analytics.js',
        '<inline script>',
        'main.dart.js',
        'flutter_bootstrap.js',
      ]);
      expect(
        scripts.where((src) => !allowedWebScripts.containsKey(src)),
        ['https://cdn.example/analytics.js', '<inline script>', 'main.dart.js'],
      );
    });
  });
}
