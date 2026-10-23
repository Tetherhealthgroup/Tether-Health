// Unit — pure functions and the screen catalog. No I/O.
//
// Extracted from the original flat test/widget_test.dart; each test was
// already self-contained, so behaviour is unchanged.

import 'package:breathefree_patient/models/screen_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog contains the complete ordered 28-screen experience', () {
    expect(approvedScreens, hasLength(28));
    expect(
      approvedScreens.map((screen) => screen.number),
      orderedEquals(List<int>.generate(28, (index) => index + 1)),
    );
    expect(approvedScreens.first.title, 'Welcome');
    expect(approvedScreens.last.title, 'Settings & privacy');
    expect(
      approvedScreens.map((screen) => screen.assetPath).toSet(),
      hasLength(28),
    );
  });
}
