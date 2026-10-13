import 'package:breathefree_patient/config/misconfigured_build_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the message at 2.0x text on a small surface',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final handle = tester.ensureSemantics();
    const message = 'Release build is misconfigured. SUPABASE_URL must use '
        'https. API_BASE_URL is missing or empty. Build with '
        '--dart-define-from-file (see docs/PLAY_RELEASE.md).';
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(320, 480),
          textScaler: TextScaler.linear(2.0),
        ),
        child: MisconfiguredBuildApp(message: message),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(message), findsOneWidget);
    expect(
      tester.getSemantics(find.text(message)),
      matchesSemantics(
        label: message,
        isLiveRegion: true,
      ),
    );
    handle.dispose();
  });
}
