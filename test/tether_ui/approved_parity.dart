// Checks the screens in tether_ui/spec/screens against the owner-approved
// registry in tether_ui/approved/ (manifest, deviations, additions). Kept free
// of file access so approved_design_parity_test.dart can run it on the real
// tree and on small synthetic fixtures. Procedure: tether_ui/approved/README.md.

import 'dart:convert';
import 'dart:typed_data';

const approvedDir = 'tether_ui/approved';
const screensDir = 'tether_ui/spec/screens';

const _procedure =
    'Do not change approved screens without an owner decision: get an owner '
    'decision, then update $approvedDir/deviations.json and deviations.md in a '
    'reviewed change (see $approvedDir/README.md).';

/// Canonical text whose sha256 pins the manifest: one `<sha256>  <screen>.json`
/// line per approved screen, sorted by screen id.
String manifestCanonicalText(Map<String, String> approved) {
  final ids = approved.keys.toList()..sort();
  return ids.map((id) => '${approved[id]}  $id.json\n').join();
}

final _hex64 = RegExp(r'^[0-9a-f]{64}$');

bool _nonBlankStrings(Object? v) =>
    v is List &&
    v.isNotEmpty &&
    v.every((e) => e is String && e.trim().isNotEmpty);

/// Decision IDs as used in the registry: `P-22`, `P-30b`,
/// `N3`, `P-47 decision 3`.
final decisionId = RegExp(r'^(P-\d+[a-z]?|N\d+|P-47 decision \d+)$');

/// Ticket IDs: `TH-942`, `TH-972a`.
final ticketId = RegExp(r'^TH-\d+[a-z]?$');

/// Values in [v] (already known to be non-blank strings) that are not IDs.
List<String> _badIds(Object? v, RegExp form) => [
      for (final e in v! as List)
        if (!form.hasMatch(e as String)) e
    ];

void _checkIds(
    List<String> failures, String what, Object? decisions, Object? tickets) {
  if (_nonBlankStrings(decisions)) {
    final bad = _badIds(decisions, decisionId);
    if (bad.isNotEmpty) {
      failures.add('$what has decisions that are not owner decision IDs: '
          '$bad. Use the decision ID (e.g. "P-22", "N3", "P-47 decision 3"); '
          'without an owner decision there is no entry: get an owner decision, '
          'then record it in a reviewed change (see $approvedDir/README.md).');
    }
  }
  if (_nonBlankStrings(tickets)) {
    final bad = _badIds(tickets, ticketId);
    if (bad.isNotEmpty) {
      failures.add('$what has tickets that are not ticket IDs: $bad. Use the '
          'ticket that made the change (e.g. "TH-942").');
    }
  }
}

/// Returns one message per problem; an empty list means the tree matches the
/// owner-approved design.
///
/// [current] maps each screen id found in [screensDir] to the sha256 of its
/// bytes. [manifestDigest] is the pinned sha256 of [manifestCanonicalText].
List<String> checkApprovedParity({
  required Object? manifest,
  required Object? deviations,
  required Object? additions,
  required Map<String, String> current,
  required int approvedCount,
  required String manifestDigest,
}) {
  final failures = <String>[];

  // Manifest: the owner's snapshot, never edited by hand.
  final approved = <String, String>{};
  final screens = manifest is Map ? manifest['screens'] : null;
  if (screens is! Map) {
    return [
      '$approvedDir/manifest.json has no "screens" object. '
          'Restore it from git; it is the owner\'s snapshot and is not edited.'
    ];
  }
  screens.forEach((k, v) {
    if (k is String && v is String && _hex64.hasMatch(v)) {
      approved[k] = v;
    } else {
      failures.add('$approvedDir/manifest.json entry "$k" is not a sha256. '
          'Restore the file from git.');
    }
  });
  if (approved.length != approvedCount) {
    failures.add('$approvedDir/manifest.json lists ${approved.length} '
        'screens; the owner approved $approvedCount. Restore the file from '
        'git.');
  }
  final digest = sha256Hex(utf8.encode(manifestCanonicalText(approved)));
  if (digest != manifestDigest) {
    failures.add('$approvedDir/manifest.json no longer matches the owner\'s '
        'snapshot (digest $digest, expected $manifestDigest). Restore it from '
        'git. Allowed differences go in deviations.json, never in the '
        'manifest.');
  }

  // Deviations: approved screens allowed to differ, pinned to reviewed bytes.
  final devs = <String, String>{};
  final devList = deviations is Map ? deviations['deviations'] : null;
  if (devList is! List) {
    failures.add('$approvedDir/deviations.json has no "deviations" list.');
  } else {
    for (final e in devList) {
      final id = e is Map ? e['screen'] : null;
      if (id is! String || id.isEmpty) {
        failures.add('$approvedDir/deviations.json has an entry without a '
            '"screen": $e');
        continue;
      }
      if (devs.containsKey(id)) {
        failures.add('Deviation "$id" is listed twice in '
            '$approvedDir/deviations.json. Keep one entry.');
        continue;
      }
      final sha = (e as Map)['sha256'];
      devs[id] = sha is String ? sha : '';
      if (!approved.containsKey(id)) {
        failures.add('Deviation "$id" is not an approved screen in '
            'manifest.json. Deviations are for approved screens only; a new '
            'screen goes in additions.json.');
      }
      if (!_nonBlankStrings(e['decisions'])) {
        failures.add('Deviation "$id" has no owner decision. $_procedure '
            'Every entry needs "decisions" (e.g. "P-22") and "tickets".');
      }
      if (!_nonBlankStrings(e['tickets'])) {
        failures.add('Deviation "$id" has no ticket. Every entry needs '
            '"decisions" and "tickets" (the ticket that made the change).');
      }
      _checkIds(failures, 'Deviation "$id"', e['decisions'], e['tickets']);
      if (sha is! String || !_hex64.hasMatch(sha)) {
        failures.add('Deviation "$id" has no valid "sha256" of the reviewed '
            'screen. $_procedure');
      } else if (sha == approved[id]) {
        failures.add('Deviation "$id" pins the approved snapshot itself. '
            'Remove the entry.');
      }
    }
  }

  // Additions: screens beyond the approved set that an owner decision added.
  final adds = <String>{};
  final addList = additions is Map ? additions['additions'] : null;
  if (addList is! List) {
    failures.add('$approvedDir/additions.json has no "additions" list.');
  } else {
    for (final e in addList) {
      final id = e is Map ? e['screen'] : null;
      if (id is! String || id.isEmpty) {
        failures.add('$approvedDir/additions.json has an entry without a '
            '"screen": $e');
        continue;
      }
      if (!adds.add(id)) {
        failures.add('Addition "$id" is listed twice in '
            '$approvedDir/additions.json. Keep one entry.');
        continue;
      }
      if (approved.containsKey(id)) {
        failures.add('Addition "$id" is an approved screen; it cannot also be '
            'an addition. Remove it from additions.json.');
      }
      if (!_nonBlankStrings((e as Map)['decisions'])) {
        failures.add('Addition "$id" has no owner decision. A new screen '
            'needs an owner decision first; then record "decisions" and '
            '"tickets" in additions.json in a reviewed change.');
      }
      if (!_nonBlankStrings(e['tickets'])) {
        failures.add('Addition "$id" has no ticket. Every entry needs '
            '"decisions" and "tickets".');
      }
      _checkIds(failures, 'Addition "$id"', e['decisions'], e['tickets']);
      if (!current.containsKey(id)) {
        failures.add('Addition "$id" is listed in additions.json but '
            '$screensDir/$id.json does not exist. Remove the entry, or '
            'restore the screen.');
      }
    }
  }

  // The screens themselves.
  for (final id in (approved.keys.toList()..sort())) {
    final now = current[id];
    final dev = devs[id];
    if (now == null) {
      failures.add('Approved screen "$id" is missing: $screensDir/$id.json '
          'does not exist. Restore it in the generator and regenerate. '
          'Removing an approved screen needs an owner decision and a reviewed '
          'change to $approvedDir/ (see README.md).');
    } else if (now == approved[id]) {
      if (dev != null) {
        failures.add('Approved screen "$id" matches the owner\'s snapshot '
            'again, but deviations.json still lists it. Remove its entry from '
            'deviations.json and deviations.md.');
      }
    } else if (dev == null) {
      failures.add('Approved screen "$id" differs from the owner\'s snapshot '
          '(manifest.json) and has no deviation entry (current sha256 $now). '
          '$_procedure Otherwise revert the change in the generator and '
          'regenerate.');
    } else if (now != dev) {
      failures.add('Approved screen "$id" has changed since its reviewed '
          'deviation (deviations.json sha256 $dev, current $now). $_procedure '
          'Otherwise revert the change in the generator and regenerate.');
    }
  }
  for (final id in (current.keys.toList()..sort())) {
    if (!approved.containsKey(id) && !adds.contains(id)) {
      failures.add('Screen "$id" ($screensDir/$id.json) is neither an '
          'owner-approved screen nor a listed addition. A new screen needs an '
          'owner decision first; then add it to $approvedDir/additions.json '
          'with "decisions" and "tickets" in a reviewed change.');
    }
  }
  return failures;
}

// SHA-256 (FIPS 180-4). The app has no direct dependency on package:crypto,
// and this test does not add one.
const _k = <int>[
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, //
  0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
  0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
  0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
  0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
  0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

const _mask = 0xffffffff;

int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & _mask;

String sha256Hex(List<int> data) {
  final h = <int>[
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, //
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ];
  final padded = ((data.length + 9 + 63) ~/ 64) * 64;
  final msg = Uint8List(padded)..setRange(0, data.length, data);
  msg[data.length] = 0x80;
  final view = ByteData.sublistView(msg);
  final bits = data.length * 8;
  view.setUint32(padded - 8, (bits ~/ 0x100000000) & _mask);
  view.setUint32(padded - 4, bits & _mask);
  final w = List<int>.filled(64, 0);
  for (var off = 0; off < padded; off += 64) {
    for (var i = 0; i < 16; i++) {
      w[i] = view.getUint32(off + 4 * i);
    }
    for (var i = 16; i < 64; i++) {
      final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
      final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & _mask;
    }
    var a = h[0], b = h[1], c = h[2], d = h[3];
    var e = h[4], f = h[5], g = h[6], hh = h[7];
    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ (~e & _mask & g);
      final t1 = (hh + s1 + ch + _k[i] + w[i]) & _mask;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final t2 = (s0 + maj) & _mask;
      hh = g;
      g = f;
      f = e;
      e = (d + t1) & _mask;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & _mask;
    }
    h[0] = (h[0] + a) & _mask;
    h[1] = (h[1] + b) & _mask;
    h[2] = (h[2] + c) & _mask;
    h[3] = (h[3] + d) & _mask;
    h[4] = (h[4] + e) & _mask;
    h[5] = (h[5] + f) & _mask;
    h[6] = (h[6] + g) & _mask;
    h[7] = (h[7] + hh) & _mask;
  }
  return h.map((x) => x.toRadixString(16).padLeft(8, '0')).join();
}
