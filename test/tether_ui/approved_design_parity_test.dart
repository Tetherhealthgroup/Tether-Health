import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'approved_parity.dart';

// Owner instruction: the UI must match Tether-Health/tether_ui. This test
// fails the build when any of the owner-approved screens in
// tether_ui/spec/screens changes without a recorded owner decision, goes
// missing, or when a screen appears that no owner decision added.
// Procedure: tether_ui/approved/README.md.

/// Number of screens in the owner's snapshot (tether_ui.zip, 2026-10-17).
const approvedScreenCount = 183;

/// sha256 of [manifestCanonicalText] for tether_ui/approved/manifest.json.
/// Changes only with a new owner snapshot.
const ownerManifestDigest =
    '540be2a16c7fa2342c6dc401b9f4165b2359a038912369629ff20326ac39776a';

Object? _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Object?;

Map<String, String> _currentScreens() {
  final out = <String, String>{};
  for (final f in Directory(screensDir).listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (name.endsWith('.json')) {
      out[name.substring(0, name.length - 5)] = sha256Hex(f.readAsBytesSync());
    }
  }
  return out;
}

String _h(String s) => sha256Hex(utf8.encode(s));

void main() {
  test('every screen matches the owner-approved design', () {
    final failures = checkApprovedParity(
      manifest: _readJson('$approvedDir/manifest.json'),
      deviations: _readJson('$approvedDir/deviations.json'),
      additions: _readJson('$approvedDir/additions.json'),
      current: _currentScreens(),
      approvedCount: approvedScreenCount,
      manifestDigest: ownerManifestDigest,
    );
    expect(failures, isEmpty, reason: '\n${failures.join('\n\n')}\n');
  });

  test('sha256 matches the FIPS 180-4 test vectors', () {
    expect(_h(''),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
    expect(_h('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
    expect(_h('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1');
    expect(_h('a' * 1000000),
        'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0');
  });

  // Self-checks: each failure mode fires on a synthetic fixture and the
  // message names the screen and the procedure.
  group('guard self-checks', () {
    late Map<String, Object?> manifest;
    late Map<String, Object?> deviations;
    late Map<String, Object?> additions;
    late Map<String, String> current;

    Map<String, Object?> dev(String id, String sha) => {
          'screen': id,
          'decisions': ['P-00'],
          'tickets': ['TH-000'],
          'sha256': sha,
        };

    setUp(() {
      manifest = {
        'screens': {'one': _h('one'), 'two': _h('two'), 'three': _h('three')},
      };
      deviations = {
        'deviations': [dev('two', _h('two v2'))],
      };
      additions = {
        'additions': [
          {
            'screen': 'extra',
            'decisions': ['P-00'],
            'tickets': ['TH-000'],
          },
        ],
      };
      current = {
        'one': _h('one'),
        'two': _h('two v2'),
        'three': _h('three'),
        'extra': _h('extra'),
      };
    });

    List<String> run({String? digest}) => checkApprovedParity(
          manifest: manifest,
          deviations: deviations,
          additions: additions,
          current: current,
          approvedCount: 3,
          manifestDigest: digest ??
              sha256Hex(utf8.encode(manifestCanonicalText({
                'one': _h('one'),
                'two': _h('two'),
                'three': _h('three'),
              }))),
        );

    void expectOne(List<String> failures, List<String> fragments) {
      expect(failures, hasLength(1), reason: failures.join('\n'));
      for (final f in fragments) {
        expect(failures.single, contains(f));
      }
    }

    test('the unmodified fixture passes', () {
      expect(run(), isEmpty);
    });

    test('an approved screen is missing', () {
      current.remove('three');
      expectOne(run(), ['"three" is missing', 'owner decision']);
    });

    test('an approved screen changed without a deviation entry', () {
      current['one'] = _h('one, edited');
      expectOne(run(), [
        '"one" differs',
        'no deviation entry',
        'get an owner decision',
        'deviations.json',
      ]);
    });

    test('a deviated screen changed beyond its reviewed deviation', () {
      current['two'] = _h('two v3');
      expectOne(run(), [
        '"two" has changed since its reviewed deviation',
        'get an owner decision',
      ]);
    });

    test('a screen that is neither approved nor a listed addition', () {
      current['stray'] = _h('stray');
      expectOne(run(), ['"stray"', 'neither', 'owner decision']);
    });

    test('a deviation entry without a decision', () {
      ((deviations['deviations']! as List).first as Map)['decisions'] =
          <String>[];
      expectOne(run(), ['Deviation "two" has no owner decision']);
    });

    test('an addition entry without a decision', () {
      ((additions['additions']! as List).first as Map).remove('decisions');
      expectOne(run(), ['Addition "extra" has no owner decision']);
    });

    test('an entry without a ticket', () {
      ((deviations['deviations']! as List).first as Map)['tickets'] = <String>[
        ''
      ];
      expectOne(run(), ['Deviation "two" has no ticket']);
    });

    test('a deviation left behind after a screen is reverted', () {
      current['two'] = _h('two');
      expectOne(run(), ['"two" matches the owner\'s snapshot again']);
    });

    test('a listed addition whose screen does not exist', () {
      current.remove('extra');
      expectOne(run(), ['Addition "extra"', 'does not exist']);
    });

    test('the manifest is edited', () {
      (manifest['screens']! as Map)['one'] = _h('one, edited');
      current['one'] = _h('one, edited');
      expectOne(run(), ['manifest.json no longer matches']);
    });

    test('an approved screen is dropped from the manifest', () {
      (manifest['screens']! as Map).remove('three');
      current.remove('three');
      final failures = run();
      expect(failures.join('\n'), contains('lists 2 screens'));
      expect(failures.join('\n'), contains('no longer matches'));
    });
  });
}
