import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_health/tether/data/bundle_loader.dart';
import 'package:tether_health/tether/data/design_bundle.dart';
import 'package:tether_health/tether/journey/journey.dart';
import 'package:tether_health/tether/router/tether_router.dart';
import 'package:tether_health/tether/screens/journey_screen_host.dart';
import 'package:tether_health/tether/screens/shell/area_directory_screen.dart';
import 'package:tether_health/tether/screens/shell/crisis_route_screen.dart';
import 'package:tether_health/tether/screens/shell/programs_home_screen.dart';
import 'package:tether_health/tether/screens/shell/record_screen.dart';
import 'package:tether_health/tether/screens/shell/remedies_screen.dart';
import 'package:tether_health/tether/screens/shell/remedy_screen.dart';
import 'package:tether_health/tether/screens/shell/sharing_matrix_screen.dart';
import 'package:tether_health/tether/state/tether_scope.dart';
import 'package:tether_health/tether/state/tether_session.dart';
import 'package:tether_health/tether/tether_app.dart';

import 'tether_bundle_test.dart' show DiskAssetBundle;

/// The app at the text sizes people actually use.
///
/// One of the eleven programmes is healthy aging, and the population this app
/// serves skews towards people who have turned the system font up. iOS offers
/// accessibility sizes past 300%; Android's font scale goes to 200% without
/// entering an accessibility mode at all. A layout that only holds together at
/// 100% is not a layout, and "the text is clipped" on a screen showing a
/// dosage boundary or a crisis number is not cosmetic.
///
/// These tests assert no exception is thrown, which in a debug build includes
/// `RenderFlex overflowed` — the yellow-and-black stripes are a thrown
/// `FlutterError`, so a clipped row fails here rather than shipping.
void main() {
  late DesignBundle bundle;

  setUpAll(() async {
    bundle = await BundleLoader.load(bundle: DiskAssetBundle());
  });

  /// A phone, not a test harness's default 800x600.
  ///
  /// Overflow is a function of how much room there is, so a viewport wider
  /// than any real handset would quietly pass rows that clip on the device in
  /// somebody's hand. 411x891 is a common Android logical size and is narrower
  /// than the default, which is the direction that matters.
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(411 * 3, 891 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<Object?> pumpAt(
    WidgetTester tester,
    Widget child,
    double scale, {
    TetherSession? state,
  }) async {
    final active = state ?? TetherSession(bundle: bundle);
    await tester.pumpWidget(
      TetherScope(
        session: active,
        child: MaterialApp(
          theme: TetherTheme.light(),
          onGenerateRoute: (settings) =>
              TetherRouter.onGenerateRoute(settings, active),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    return tester.takeException();
  }

  /// 1.0 is the baseline, 2.0 is the largest non-accessibility Android scale,
  /// 3.0 is roughly iOS's largest accessibility size. Three points rather than
  /// a sweep, because each one renders every screen in the app.
  const scales = <double>[1.0, 2.0, 3.0];

  group('the shell holds up', () {
    for (final scale in scales) {
      testWidgets('at ${scale}x', (tester) async {
        usePhone(tester);
        final failures = <String>[];

        final screens = <String, Widget Function()>{
          'programs': () => const ProgramsHomeScreen(),
          'areas': () => const AreaDirectoryScreen(),
          'record': () => const RecordScreen(),
          'sharing': () => const SharingMatrixScreen(),
          'crisis': () => const CrisisRouteScreen(),
          'remedies': () => const RemediesScreen(),
        };

        for (final entry in screens.entries) {
          final error = await pumpAt(tester, entry.value(), scale);
          if (error != null) failures.add('${entry.key}: $error');
        }

        expect(failures, isEmpty, reason: failures.join('\n\n'));
      });
    }
  });

  group('every program screen holds up', () {
    for (final scale in scales) {
      testWidgets('at ${scale}x', (tester) async {
        usePhone(tester);
        final failures = <String>[];
        var built = 0;

        for (final journey in JourneyBuilder.all(bundle)) {
          for (final screen in journey.screens) {
            final error = await pumpAt(
              tester,
              JourneyScreenHost(
                screen: screen,
                journey: journey,
                onNavigate: (_) {},
              ),
              scale,
            );
            if (error != null) {
              failures.add('${journey.area.id}/${screen.id}: $error');
            } else {
              built++;
            }
          }
        }

        expect(failures, isEmpty, reason: failures.take(10).join('\n\n'));
        expect(built, 237);
      });
    }
  });

  group('every remedy holds up', () {
    for (final scale in scales) {
      testWidgets('at ${scale}x', (tester) async {
        usePhone(tester);
        final failures = <String>[];

        for (final remedy in bundle.remedies) {
          final error = await pumpAt(tester, const RemediesScreen(), scale);
          if (error != null) failures.add('library: $error');
          final detail =
              await pumpAt(tester, RemedyScreen(remedy: remedy), scale);
          if (detail != null) failures.add('${remedy.id}: $detail');
        }

        expect(failures, isEmpty, reason: failures.join('\n\n'));
      });
    }
  });
}
