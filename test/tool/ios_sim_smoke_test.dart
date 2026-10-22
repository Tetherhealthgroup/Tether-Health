import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Checks tool/ios_sim_smoke.sh, the local iOS Simulator smoke check.
//
// The static group pins the script's safety rules: no signing, packaging,
// store or phone tooling is named anywhere in it; it builds only the debug
// simulator app, with TETHER_UI as the only define; every simctl call targets
// the simulator resolved from `simctl list devices available`; the output
// folder must be outside the repository; and app log lines are counted, never
// printed.
//
// The run groups execute a copy of the script, under /bin/sh and (if present)
// dash, with fake uname, sleep, ps, xcrun and flutter commands on PATH.
// Nothing is built or booted: the fake flutter writes a Runner.app Info.plist,
// the fake xcrun answers a synthetic simulator list, keeps boot and ui state
// in a folder and logs every call, and the fake ps reports the app process.
// Scenario files choose a dead process, a crash report, a crash marker in the
// log, a failing screenshot, or a wrong bundle ID or platform.

String join(List<String> parts) => parts.join(Platform.pathSeparator);

const String scriptPath = 'tool/ios_sim_smoke.sh';
const String bundleId = 'com.TetherHealthLLC.tetherhealth';

/// A comment-only line: optional spaces or tabs, then `#`.
final RegExp commentLine = RegExp(r'^[ \t]*#');

/// The script's lines without comment lines and blank lines.
List<String> codeLines(String source) => source
    .split('\n')
    .where((l) => !commentLine.hasMatch(l) && l.trim().isNotEmpty)
    .toList();

/// [line] with the text of every `fail "..."` and `echo "..."` message
/// blanked, so that a message naming a command is not taken for a call.
String withoutMessages(String line) =>
    line.replaceAll(RegExp(r'\b(fail|echo) "[^"]*"'), 'MSG');

/// Text that must not appear anywhere in the script, comments included,
/// matched case-insensitively: signing, packaging, store delivery, phone
/// tooling, release or profile builds, and simctl's `booted` device alias
/// (which can pick a simulator other than the resolved one).
final List<RegExp> forbiddenText = [
  for (final word in [
    'codesign',
    'archive',
    'export',
    'altool',
    'notarytool',
    'devicectl',
    'upload',
    'ios-deploy',
    'idevice',
    'iphoneos',
    'xcodebuild',
    'mobileprovision',
    'provisioning',
    'keychain',
    'testflight',
    'transporter',
    'fastlane',
    'development_team',
    '--release',
    '--profile',
    'dart-define-from-file',
  ])
    RegExp(RegExp.escape(word), caseSensitive: false),
  RegExp(r'\bipa\b', caseSensitive: false),
  RegExp(r'\.p8\b', caseSensitive: false),
  RegExp(r'app\s*store\s*connect', caseSensitive: false),
  RegExp(r'\bsecurity\s+(find|import|unlock|add|set|create)',
      caseSensitive: false),
  RegExp(r'flutter\s+(run|install|attach|drive)\b', caseSensitive: false),
  RegExp(r'simctl[ \t]+\S+[ \t]+(\S+[ \t]+)*booted\b', caseSensitive: false),
];

/// The only lines that name flutter.
const List<String> pinnedFlutterLines = [
  r'command -v flutter >/dev/null 2>&1 || fail "flutter not found on PATH."',
  r'  echo "== flutter build ios --simulator --debug --dart-define=TETHER_UI=true"',
  r'  flutter build ios --simulator --debug --dart-define=TETHER_UI=true || fail "flutter build failed."',
  r'  echo "== flutter build ios --simulator --debug"',
  r'  flutter build ios --simulator --debug || fail "flutter build failed."',
];

/// The only line that reads the simulator list, and the device refusals.
const String pinnedListLine =
    r'simulators=$(xcrun simctl list devices available -j) || fail "xcrun simctl list devices available failed."';
const List<String> pinnedResolveCase = [
  r'case "$resolve_status" in',
  r'  0) ;;',
  r'''  3) fail "--device is not an available iOS Simulator listed by 'xcrun simctl list devices available' (value not shown). Physical devices are never used." 2 ;;''',
  r'  4) fail "--device names several simulators on the newest iOS runtime; pass the UDID instead." 2 ;;',
  r'  *) fail "cannot read the simulator list." ;;',
  r'esac',
];

/// Lines of the resolver that limit it to available iOS Simulators.
const List<String> pinnedResolverLines = [
  r'''    m = re.fullmatch(r"com\.apple\.CoreSimulator\.SimRuntime\.iOS-(\d+)-(\d+)(?:-(\d+))?", runtime)''',
  r'''        if d.get("isAvailable") is True:''',
  r'''if not re.fullmatch(r"[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}", udid):''',
];

/// The output-folder check.
const List<String> pinnedOutCheck = [
  r'case "$out_real/" in',
  r'  "$repo_root"/*) fail "--out is inside the repository. Use a folder outside it." 2 ;;',
  r'esac',
];

/// simctl subcommands the script may run, each against "$udid".
const Set<String> allowedSimctl = {
  'boot',
  'bootstatus',
  'ui',
  'install',
  'launch',
  'io',
  'spawn',
  'terminate',
  'shutdown',
  'status_bar',
};

/// Every line that mentions the log file: created, counted, removed.
const List<String> pinnedLogFileLines = [
  r'log_file="$tmp/app.log"',
  r'''  --predicate "processIdentifier == $pid" >"$log_file" 2>/dev/null || : >"$log_file"''',
  r'''log_lines=$(grep -c '^{' "$log_file" || true)''',
  r'''  -e 'EXC_CRASH' -e 'SIGABRT' -e 'SIGSEGV' -e 'Fatal error' "$log_file" || true)''',
  r'''dart_markers=$(grep -c -e 'Unhandled Exception' -e 'EXCEPTION CAUGHT BY' "$log_file" || true)''',
  r'rm -f "$log_file"',
];

void main() {
  final source = File(scriptPath).readAsStringSync();
  final code = codeLines(source);

  int indexOf(String line) {
    final i = code.indexOf(line);
    expect(i, isNot(-1), reason: 'line not found: $line');
    return i;
  }

  void expectBlock(List<String> pinned) {
    final start = indexOf(pinned.first);
    expect(start + pinned.length, lessThanOrEqualTo(code.length));
    expect(code.sublist(start, start + pinned.length), pinned);
  }

  group('static', () {
    test('is a POSIX sh script that stops on errors', () {
      expect(source.split('\n').first, '#!/bin/sh');
      expect(code, contains('set -eu'));
      expect(code, contains('bundle_id="$bundleId"'));
    });

    test('names no signing, packaging, store or phone tooling', () {
      for (final pattern in forbiddenText) {
        expect(pattern.hasMatch(source), isFalse,
            reason: 'forbidden text: ${pattern.pattern}');
      }
    });

    test('builds only the debug simulator app; TETHER_UI is the only define',
        () {
      final flutterLines =
          code.where((l) => RegExp(r'\bflutter\b').hasMatch(l)).toList();
      expect(flutterLines, pinnedFlutterLines);
      final defines = RegExp(r'dart-define[^\s"]*')
          .allMatches(source)
          .map((m) => m.group(0))
          .toSet();
      expect(defines, {'dart-define=TETHER_UI=true'});
    });

    test('resolves the device from the simulator list before anything runs',
        () {
      expect(code.where((l) => withoutMessages(l).contains('simctl list')),
          [pinnedListLine]);
      expectBlock(pinnedResolveCase);
      for (final line in pinnedResolverLines) {
        indexOf(line);
      }
      final resolved = indexOf(pinnedResolveCase.first);
      expect(indexOf(pinnedFlutterLines[2]), greaterThan(resolved));
      expect(indexOf(pinnedFlutterLines[4]), greaterThan(resolved));
      final firstSimctlUse = code.indexWhere(
          (l) => RegExp(r'simctl (?!list)').hasMatch(withoutMessages(l)));
      expect(firstSimctlUse, greaterThan(resolved));
    });

    test('every simctl call targets the resolved simulator', () {
      final calls = code
          .map(withoutMessages)
          .where((l) => l.contains('simctl') && !l.contains('simctl list'))
          .toList();
      expect(calls, isNotEmpty);
      final call = RegExp(r'xcrun simctl (\S+) ((?:--\S+ )*)"\$udid"');
      for (final line in calls) {
        final m = call.firstMatch(line);
        expect(m, isNotNull, reason: 'simctl call without "\$udid": $line');
        expect(allowedSimctl, contains(m!.group(1)), reason: line);
      }
      for (final line in code.where((l) => l.contains('simctl spawn'))) {
        expect(line, contains('simctl spawn "\$udid" log show '));
      }
    });

    test('installs only an iOS Simulator build of the app', () {
      final platform = indexOf(
          r'''[ "$(plist_value CFBundleSupportedPlatforms 2>/dev/null)" = "iPhoneSimulator" ] ||''');
      final identifier = indexOf(
          r'''[ "$(plist_value CFBundleIdentifier 2>/dev/null)" = "$bundle_id" ] ||''');
      final install = indexOf(
          r'xcrun simctl install "$udid" "$app" || fail "xcrun simctl install failed."');
      expect(indexOf(r'app="$repo_root/build/ios/iphonesimulator/Runner.app"'),
          lessThan(platform));
      expect(platform, lessThan(install));
      expect(identifier, lessThan(install));
    });

    test('refuses an output folder inside the repository', () {
      expectBlock(pinnedOutCheck);
      final check = indexOf(pinnedOutCheck.first);
      final create = indexOf(
          r'[ -d "$out_real" ] || mkdir "$out_real" || fail "cannot create the --out folder (path not shown)."');
      expect(create, greaterThan(check));
      expect(code.where((l) => l.contains('mkdir')).length, 1);
      final writes = code.where((l) => l.contains('screenshot')).toList();
      expect(writes.where((l) => withoutMessages(l).contains('simctl io')), [
        r'''      xcrun simctl io "$udid" screenshot --type=png "$out_real/$shot" >/dev/null 2>&1 ||'''
      ]);
    });

    test('counts app log lines and never prints them', () {
      expect(code.where((l) => l.contains('log_file')).toList(),
          pinnedLogFileLines);
      expect(code.where((l) => l.contains('log show')), [
        r'xcrun simctl spawn "$udid" log show --style ndjson --start "$log_start" \'
      ]);
    });

    test('exits non-zero when the app is not alive or crashed', () {
      expectBlock([
        r'if [ "$alive_first" -ne 1 ] || [ "$alive_last" -ne 1 ] || [ "$fatal_markers" -ne 0 ] || [ "$crash_reports" -ne 0 ]; then',
        r'  fail "FAIL: the app crashed or exited."',
        r'fi',
        r'echo "PASS: the app stayed up."',
      ]);
      expect(code.last, r'echo "PASS: the app stayed up."');
    });
  });

  final shells = [
    '/bin/sh',
    if (File('/bin/dash').existsSync()) '/bin/dash',
  ];
  for (final shell in shells) {
    group('run with fake tools ($shell)', () => runGroup(shell),
        skip: Platform.isWindows ? 'needs /bin/sh' : null);
  }
}

const String iosUdid = '0A1B2C3D-0000-4000-8000-00000000A001';
const String olderUdid = '0A1B2C3D-0000-4000-8000-00000000A002';
const String watchUdid = '0A1B2C3D-0000-4000-8000-00000000A003';
const String unavailableUdid = '0A1B2C3D-0000-4000-8000-00000000A004';
const String twinUdid1 = '0A1B2C3D-0000-4000-8000-00000000A005';
const String twinUdid2 = '0A1B2C3D-0000-4000-8000-00000000A006';

/// The fake simulator list. The fake xcrun replaces @STATE@ (the state of
/// [iosUdid]) with Booted or Shutdown.
const String simulatorList = '''
{"devices": {
  "com.apple.CoreSimulator.SimRuntime.iOS-27-0": [
    {"udid": "$iosUdid", "name": "Synthetic Phone", "state": "@STATE@", "isAvailable": true},
    {"udid": "$twinUdid1", "name": "Twin Phone", "state": "Shutdown", "isAvailable": true},
    {"udid": "$twinUdid2", "name": "Twin Phone", "state": "Shutdown", "isAvailable": true},
    {"udid": "$unavailableUdid", "name": "Gone Phone", "state": "Shutdown", "isAvailable": false}
  ],
  "com.apple.CoreSimulator.SimRuntime.iOS-26-4": [
    {"udid": "$olderUdid", "name": "Synthetic Phone", "state": "Shutdown", "isAvailable": true}
  ],
  "com.apple.CoreSimulator.SimRuntime.watchOS-27-0": [
    {"udid": "$watchUdid", "name": "Synthetic Watch", "state": "Shutdown", "isAvailable": true}
  ]
}}
''';

/// A synthetic app log line that must never reach the script's output.
const String logCanary = 'synthetic-log-canary-91c2';

/// Fake xcrun: logs every call to $FAKE/calls and keeps the boot, appearance
/// and text-size state in $FAKE. Files in $FAKE choose the scenario:
/// crash_report (launch writes a crash report), fail_io (screenshots fail).
const String fakeXcrun = r'''#!/bin/sh
f="$FAKE"
echo "$*" >> "$f/calls"
[ "$1" = simctl ] || exit 1
shift
case "$1" in
  list)
    [ "$*" = "list devices available -j" ] || exit 1
    state=Shutdown
    [ -e "$f/booted" ] && state=Booted
    sed "s/@STATE@/$state/" "$f/list.json"
    ;;
  boot) touch "$f/booted" ;;
  shutdown) rm -f "$f/booted" ;;
  bootstatus) [ -e "$f/booted" ] || exit 1 ;;
  ui)
    if [ $# -ge 4 ]; then
      printf '%s\n' "$4" > "$f/ui_$3"
    elif [ -e "$f/ui_$3" ]; then
      cat "$f/ui_$3"
    elif [ "$3" = appearance ]; then
      echo light
    else
      echo large
    fi
    ;;
  status_bar | install | terminate) ;;
  launch)
    if [ -e "$f/crash_report" ]; then
      reports="$HOME/Library/Logs/DiagnosticReports"
      mkdir -p "$reports"
      printf '{"app_name":"Runner","bundleID":"com.TetherHealthLLC.tetherhealth"}\n{}\n' > "$reports/Runner-1.ips"
      touch -t 203001010000 "$reports/Runner-1.ips"
    fi
    echo "com.TetherHealthLLC.tetherhealth: 4242"
    ;;
  io)
    [ -e "$f/fail_io" ] && exit 1
    for a; do out="$a"; done
    printf 'png %s %s\n' "$(cat "$f/ui_appearance")" "$(cat "$f/ui_content_size")" > "$out"
    ;;
  spawn) cat "$f/app.log" ;;
  *) exit 1 ;;
esac
''';

/// Fake flutter: records its arguments, then writes a Runner.app whose
/// Info.plist holds $FAKE/bundle_id and $FAKE/platform, unless
/// $FAKE/flutter_fail exists.
const String fakeFlutter = r'''#!/bin/sh
echo "$*" >> "$FAKE/flutter_args"
[ -e "$FAKE/flutter_fail" ] && exit 1
app=build/ios/iphonesimulator/Runner.app
mkdir -p "$app"
cat > "$app/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>$(cat "$FAKE/bundle_id")</string>
<key>CFBundleSupportedPlatforms</key><array><string>$(cat "$FAKE/platform")</string></array>
</dict></plist>
EOF
''';

void runGroup(String shell) {
  late Directory root;
  late Directory outside;
  late Directory fake;
  late String script;

  File fakeFile(String name) => File(join([fake.path, name]));
  void scenario(String name, [String contents = '']) =>
      fakeFile(name).writeAsStringSync(contents);

  setUp(() {
    root = Directory.systemTemp.createTempSync('ios_sim_smoke_repo');
    outside = Directory.systemTemp.createTempSync('ios_sim_smoke_out');
    fake = Directory(join([outside.path, 'fake']))..createSync();
    Directory(join([root.path, 'tool'])).createSync();
    script = join([root.path, 'tool', 'ios_sim_smoke.sh']);
    File(scriptPath).copySync(script);
    final bin = Directory(join([root.path, 'bin']))..createSync();
    final python = Process.runSync('which', ['python3']).stdout.toString();
    Link(join([bin.path, 'python3'])).createSync(python.trim());
    scenario('list.json', simulatorList);
    scenario('bundle_id', bundleId);
    scenario('platform', 'iPhoneSimulator');
    scenario('app.log',
        '{"eventMessage":"$logCanary one"}\n{"eventMessage":"$logCanary two"}\n');
    final fakes = {
      'uname': '#!/bin/sh\necho Darwin\n',
      'sleep': '#!/bin/sh\nexit 0\n',
      'ps': '#!/bin/sh\n'
          '[ -e "\$FAKE/dead" ] && exit 1\n'
          'if [ -e "\$FAKE/dies_late" ]; then\n'
          '  [ -e "\$FAKE/ps_seen" ] && exit 1\n'
          '  touch "\$FAKE/ps_seen"\n'
          'fi\n'
          'echo /fake/Runner.app/Runner\n',
      'flutter': fakeFlutter,
      'xcrun': fakeXcrun,
    };
    for (final entry in fakes.entries) {
      final file = File(join([bin.path, entry.key]))
        ..writeAsStringSync(entry.value);
      Process.runSync('chmod', ['+x', file.path]);
    }
  });

  tearDown(() {
    root.deleteSync(recursive: true);
    outside.deleteSync(recursive: true);
  });

  ProcessResult run(List<String> args) => Process.runSync(
        shell,
        [script, ...args],
        environment: {
          'PATH': '${root.path}/bin:/usr/bin:/bin',
          'HOME': outside.path,
          'FAKE': fake.path,
        },
        includeParentEnvironment: false,
      );

  String output(ProcessResult r) => '${r.stdout}${r.stderr}';
  String shotsPath() => join([outside.path, 'shots']);
  String outArg() => '--out=${shotsPath()}';
  List<String> calls() => fakeFile('calls').existsSync()
      ? fakeFile('calls').readAsLinesSync()
      : const [];
  bool called(String prefix) => calls().any((c) => c.startsWith(prefix));
  int callIndex(String call) => calls().indexOf(call);
  bool flutterRan() => fakeFile('flutter_args').existsSync();

  group('arguments and device', () {
    setUp(() => scenario('flutter_fail'));

    test('refuses other defines and build modes without showing values', () {
      const canary = 'synthetic-canary-7f3a';
      for (final args in [
        ['--dart-define=TETHER_UI=false'],
        ['--dart-define=SUPABASE_URL=https://$canary.example.test'],
        ['--dart-define-from-file=/$canary.json'],
        ['--release'],
        ['--profile'],
        ['--flavor=$canary'],
        ['--device=$iosUdid', outArg(), '--tether-ui=$canary'],
      ]) {
        final r = run(args);
        expect(r.exitCode, 2, reason: '$args: ${output(r)}');
        expect(output(r), contains('unknown argument'));
        expect(output(r), isNot(contains(canary)));
      }
      expect(flutterRan(), isFalse);
      expect(calls(), isEmpty);
    });

    test('refuses shell syntax in --device before calling any tool', () {
      for (final device in [
        r'Synthetic Phone$(touch pwned)',
        'Synthetic Phone;id',
        'Synthetic Phone`id`',
        'a|b',
      ]) {
        final r = run(['--device=$device', outArg()]);
        expect(r.exitCode, 2, reason: '$device: ${output(r)}');
        expect(output(r), contains('--device may hold only'));
      }
      expect(calls(), isEmpty);
      expect(flutterRan(), isFalse);
    });

    test('refuses an output folder inside the repository', () {
      final inside = Directory(join([root.path, 'shots']))..createSync();
      for (final out in [
        inside.path,
        join([root.path, 'new_folder']),
        join([inside.path, 'new_folder']),
        root.path,
      ]) {
        final r = run(['--device=$iosUdid', '--out=$out']);
        expect(r.exitCode, 2, reason: output(r));
        expect(output(r), contains('--out is inside the repository'));
      }
      expect(Directory(join([root.path, 'new_folder'])).existsSync(), isFalse);
      expect(calls(), isEmpty);
    });

    test('refuses another spelling of a folder in the repository', () {
      final real = root.resolveSymbolicLinksSync();
      final name = real.split('/').last;
      final swapped = name
          .split('')
          .map((c) => c == c.toUpperCase() ? c.toLowerCase() : c.toUpperCase())
          .join();
      final parent = real.substring(0, real.length - name.length);
      final spellings = [
        // Another letter case of the repository root.
        '$parent$swapped',
        // The same folder through the data-volume path.
        if (Directory('/System/Volumes/Data$real').existsSync())
          '/System/Volumes/Data$real',
      ];
      Directory(join([root.path, 'shots'])).createSync();
      var checked = 0;
      for (final spelling in spellings) {
        final sameFolder = Directory(spelling).existsSync() &&
            FileSystemEntity.identicalSync(spelling, real);
        for (final sub in ['shots', 'new_folder', 'shots/new_folder']) {
          final r = run(['--device=$iosUdid', '--out=$spelling/$sub']);
          expect(r.exitCode, 2, reason: '$spelling/$sub: ${output(r)}');
          if (sameFolder) {
            expect(output(r), contains('--out is inside the repository'),
                reason: '$spelling/$sub');
          }
        }
        if (sameFolder) checked++;
      }
      expect(Directory(join([root.path, 'new_folder'])).existsSync(), isFalse);
      expect(Directory(join([root.path, 'shots', 'new_folder'])).existsSync(),
          isFalse);
      expect(calls(), isEmpty);
      if (Platform.isMacOS) expect(checked, greaterThan(0));
    });

    test('refuses a device that is not an available iOS Simulator', () {
      for (final device in [
        // A phone-style identifier never appears in the simulator list.
        '00008110-001A2B3C4D5E801E',
        '0A1B2C3D-0000-4000-8000-0000000000FF',
        watchUdid,
        unavailableUdid,
        'Synthetic Watch',
        'Gone Phone',
        'synthetic phone',
      ]) {
        final r = run(['--device=$device', outArg()]);
        expect(r.exitCode, 2, reason: '$device: ${output(r)}');
        expect(output(r), contains('is not an available iOS Simulator'));
        expect(output(r), isNot(contains(device)));
      }
      final twin = run(['--device=Twin Phone', outArg()]);
      expect(twin.exitCode, 2);
      expect(output(twin), contains('pass the UDID instead'));
      expect(flutterRan(), isFalse);
      expect(calls().toSet(), {'simctl list devices available -j'});
      expect(Directory(shotsPath()).existsSync(), isFalse);
    });

    test('builds the debug simulator app for a listed simulator', () {
      final r = run(['--device=$iosUdid', outArg()]);
      expect(r.exitCode, 1, reason: output(r));
      expect(output(r), contains('flutter build failed.'));
      expect(fakeFile('flutter_args').readAsStringSync(),
          'build ios --simulator --debug\n');
      expect(Directory(shotsPath()).existsSync(), isTrue);
      expect(calls(), ['simctl list devices available -j']);
    });

    test('--tether-ui adds only the TETHER_UI define', () {
      final r = run(['--tether-ui', '--device=Synthetic Phone', outArg()]);
      expect(r.exitCode, 1, reason: output(r));
      expect(fakeFile('flutter_args').readAsStringSync(),
          'build ios --simulator --debug --dart-define=TETHER_UI=true\n');
    });

    test('rejects alive-seconds outside 5 to 600', () {
      for (final value in ['4', '601', '0', '-1', '10s', '', '00020']) {
        final r =
            run(['--device=$iosUdid', outArg(), '--alive-seconds=$value']);
        expect(r.exitCode, 2, reason: '$value: ${output(r)}');
      }
      expect(flutterRan(), isFalse);
    });
  });

  group('full flow', () {
    test('passes, saves four screenshots and never prints log lines', () {
      final r = run(['--device=$iosUdid', outArg()]);
      expect(r.exitCode, 0, reason: output(r));
      expect(output(r), contains('PASS: the app stayed up.'));
      expect(output(r), contains('process 4242 alive after 20s: yes'));
      expect(output(r), contains('app log lines: 2; native crash markers: 0'));
      expect(output(r), isNot(contains(logCanary)));
      final shots = Directory(shotsPath())
          .listSync()
          .map((e) => e.path.split(Platform.pathSeparator).last)
          .toSet();
      expect(shots, {
        'legacy-light-default-text.png',
        'legacy-light-ax-xl-text.png',
        'legacy-dark-default-text.png',
        'legacy-dark-ax-xl-text.png',
      });
      expect(
          callIndex(
              'simctl install $iosUdid ${root.resolveSymbolicLinksSync()}/build/ios/iphonesimulator/Runner.app'),
          isNot(-1));
      expect(called('simctl terminate $iosUdid $bundleId'), isTrue);
    });

    test('never shuts down a simulator that was already booted', () {
      for (final args in [
        <String>[],
        ['--keep-booted'],
      ]) {
        scenario('booted');
        fakeFile('calls').writeAsStringSync('');
        final r = run(['--device=$iosUdid', outArg(), ...args]);
        expect(r.exitCode, 0, reason: output(r));
        expect(called('simctl boot '), isFalse, reason: '$args');
        expect(called('simctl shutdown'), isFalse, reason: '$args');
        expect(fakeFile('booted').existsSync(), isTrue);
      }
    });

    test('shuts down a simulator it booted, after restoring it', () {
      final r = run(['--device=$iosUdid', outArg()]);
      expect(r.exitCode, 0, reason: output(r));
      final shutdown = callIndex('simctl shutdown $iosUdid');
      expect(callIndex('simctl boot $iosUdid'), isNot(-1));
      expect(shutdown, isNot(-1));
      expect(shutdown, calls().length - 1);
      expect(callIndex('simctl status_bar $iosUdid clear'),
          allOf(isNot(-1), lessThan(shutdown)));
      expect(callIndex('simctl terminate $iosUdid $bundleId'),
          allOf(isNot(-1), lessThan(shutdown)));
      expect(fakeFile('booted').existsSync(), isFalse);
    });

    test('--keep-booted leaves a simulator it booted running', () {
      final r = run(['--device=$iosUdid', outArg(), '--keep-booted']);
      expect(r.exitCode, 0, reason: output(r));
      expect(callIndex('simctl boot $iosUdid'), isNot(-1));
      expect(called('simctl shutdown'), isFalse);
      expect(fakeFile('booted').existsSync(), isTrue);
    });

    test('stops before boot and install on a wrong bundle ID or platform', () {
      for (final entry in {
        'bundle_id': 'com.example.synthetic',
        'platform': 'iPhoneOS',
      }.entries) {
        scenario('bundle_id', bundleId);
        scenario('platform', 'iPhoneSimulator');
        scenario(entry.key, entry.value);
        final r = run(['--device=$iosUdid', outArg()]);
        expect(r.exitCode, 1, reason: '${entry.key}: ${output(r)}');
        expect(output(r), contains('the built app'));
        expect(called('simctl install'), isFalse, reason: entry.key);
        expect(called('simctl boot'), isFalse, reason: entry.key);
      }
    });

    test('fails when the app process has exited', () {
      scenario('dead');
      final r = run(['--device=$iosUdid', outArg()]);
      expect(r.exitCode, 1, reason: output(r));
      expect(output(r), contains('process 4242 alive after 20s: no'));
      expect(output(r), contains('FAIL: the app crashed or exited.'));
      expect(output(r), isNot(contains('PASS')));
      expect(called('simctl io'), isFalse);
    });

    test('fails when the app process exits during the screenshots', () {
      scenario('dies_late');
      final r = run(['--device=$iosUdid', outArg()]);
      expect(r.exitCode, 1, reason: output(r));
      expect(output(r), contains('process 4242 alive after 20s: yes'));
      expect(output(r), contains('process 4242 alive after screenshots: no'));
      expect(output(r), contains('FAIL: the app crashed or exited.'));
    });

    test('fails on a crash report for the app', () {
      scenario('crash_report');
      final r = run(['--device=$iosUdid', outArg()]);
      expect(r.exitCode, 1, reason: output(r));
      expect(
          output(r), contains('crash reports for $bundleId since launch: 1'));
      expect(output(r), contains('FAIL: the app crashed or exited.'));
    });

    test('fails on a native crash marker without printing it', () {
      scenario('app.log',
          '{"eventMessage":"$logCanary"}\n{"eventMessage":"$logCanary SIGABRT"}\n');
      final r = run(['--device=$iosUdid', outArg()]);
      expect(r.exitCode, 1, reason: output(r));
      expect(output(r), contains('native crash markers: 1'));
      expect(output(r), contains('FAIL: the app crashed or exited.'));
      expect(output(r), isNot(contains(logCanary)));
    });

    test('a failed step still stops the app and restores the simulator', () {
      scenario('fail_io');
      final r = run(['--device=$iosUdid', outArg()]);
      expect(r.exitCode, 1, reason: output(r));
      expect(output(r), contains('xcrun simctl io screenshot failed.'));
      final shutdown = callIndex('simctl shutdown $iosUdid');
      expect(shutdown, calls().length - 1);
      expect(callIndex('simctl terminate $iosUdid $bundleId'),
          allOf(isNot(-1), lessThan(shutdown)));
      expect(callIndex('simctl status_bar $iosUdid clear'),
          allOf(isNot(-1), lessThan(shutdown)));
      expect(called('simctl ui $iosUdid appearance light'), isTrue);
    });
  });
}
