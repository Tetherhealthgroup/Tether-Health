// SHA-256 against the FIPS 180-4 example vectors.
import 'dart:convert';

import 'package:breathefree_patient/backend/sandbox/sha256.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('known digests', () {
    expect(hex(sha256(utf8.encode(''))),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
    expect(hex(sha256(utf8.encode('abc'))),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
    expect(
        hex(sha256(utf8.encode(
            'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'))),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1');
    expect(hex(sha256(List<int>.filled(1000000, 0x61))),
        'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0');
  });
}
