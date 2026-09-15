import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_health/tether/data/bundle_loader.dart';
import 'package:tether_health/tether/data/design_bundle.dart';
import 'package:tether_health/tether/journey/journey.dart';
import 'package:tether_health/tether/router/tether_router.dart';
import 'package:tether_health/tether/screens/artwork_screen.dart';
import 'package:tether_health/tether/screens/content_screen.dart';
import 'package:tether_health/tether/screens/journey_screen_host.dart';
import 'package:tether_health/tether/screens/program_overview_screen.dart';
import 'package:tether_health/tether/screens/shell/area_directory_screen.dart';
import 'package:tether_health/tether/screens/shell/crisis_route_screen.dart';
import 'package:tether_health/tether/screens/shell/programs_home_screen.dart';
import 'package:tether_health/tether/screens/unbuilt_screen.dart';
import 'package:tether_health/tether/screens/unwritten_screen.dart';
import 'package:tether_health/tether/state/tether_scope.dart';
import 'package:tether_health/tether/state/tether_session.dart';
import 'package:tether_health/tether/tether_app.dart';

import 'tether_bundle_test.dart' show DiskAssetBundle;

/// Does every screen in every program actually build?
///
/// There are 237 of them across the eleven areas and almost none are reachable
/// by hand in a review session. A renderer that throws on one archetype's slot
/// combination would be found by a patient rather than by anybody here, so the
/// last test in this file pumps all of them.
void main() {
  late DesignBundle bundle;

  setUpAll(() async {
    bundle = await BundleLoader.load(bundle: DiskAssetBundle());
  });

  TetherSession session() => TetherSession(bundle: bundle);

  /// Pumps [child] inside the scope and theme the real app supplies.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    TetherSession? state,
  }) async {
    final active = state ?? session();
    await tester.pumpWidget(
      TetherScope(
        session: active,
        child: MaterialApp(
          theme: TetherTheme.light(),
          home: child,
          onGenerateRoute: (settings) =>
              TetherRouter.onGenerateRoute(settings, active),
        ),
      ),
    );
    await tester.pump();
  }

  group('the shell', () {
    testWidgets('opens on Your programs', (tester) async {
      await pump(tester, const ProgramsHomeScreen());
      expect(find.byType(ProgramsHomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the area directory lists all eleven areas', (tester) async {
      await pump(tester, const AreaDirectoryScreen());
      await tester.pumpAndSettle();

      // Every area must be named. Scrolling is allowed; omission is not — the
      // directory's whole contract is being honest about all eleven.
      //
      // The search restarts from the top for each area. SH2 groups its rows by
      // status and the groups run most-advanced first, so catalogue order is
      // no longer display order: `nutrition` is fifth in the catalogue and
      // eighth on the screen, and `respiratory` is sixth in the catalogue and
      // fifth on the screen. `scrollUntilVisible` only ever scrolls one way, so
      // without the reset it would scroll past `respiratory` looking for
      // `nutrition` and then report the area it had already gone by as
      // missing — a false failure that says "omitted" about a row that is
      // drawn.
      final scrollable = find.byType(Scrollable).first;
      for (final area in bundle.areas) {
        tester.state<ScrollableState>(scrollable).position.jumpTo(0);
        await tester.pump();
        await tester.scrollUntilVisible(
          find.text(area.name),
          200,
          scrollable: scrollable,
        );
        expect(find.text(area.name), findsWidgets, reason: area.id);
      }
    });

    testWidgets('the crisis route builds and is reachable', (tester) async {
      await pump(tester, const CrisisRouteScreen());
      await tester.pumpAndSettle();
      expect(find.byType(CrisisRouteScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the home screen never lists the eleven areas', (tester) async {
      // `no_area_directory_on_home`, checked against what is actually drawn
      // rather than only against the archetype's slots. A person picking up a
      // shared phone must not learn from the home screen that somebody is
      // dealing with cancer.
      final state = session();
      state.join('digital');
      await pump(tester, const ProgramsHomeScreen(), state: state);
      await tester.pumpAndSettle();

      final leaked = bundle.areas
          .where((area) => !state.enrolment(area.id).isJoined)
          .where((area) => find.text(area.name).evaluate().isNotEmpty)
          .map((area) => area.id)
          .toList();
      expect(
        leaked,
        isEmpty,
        reason: 'the home screen named areas nobody has joined: $leaked',
      );
    });
  });

  group('journey screens render in all three states', () {
    late Journey lookup;

    setUp(() => lookup = JourneyBuilder.forArea(bundle, bundle.area('digital')!));

    testWidgets('an authored screen renders its own copy', (tester) async {
      final today = lookup.screen('S12')!;
      await pump(
        tester,
        JourneyScreenHost(
          screen: today,
          journey: lookup,
          onNavigate: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ContentScreen), findsOneWidget);
      expect(find.text(today.content!.headline!), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unwritten screen says so', (tester) async {
      // Neither product the bundle ships has an unwritten screen left: LookUp's
      // copy is complete and BreatheFree's screens are approved artwork. Every
      // unwritten screen in the app is now a shell screen, SH1..SH6, in one of
      // the eight programmes written here — six each, and deliberately so.
      // Those six are drawn by the host shell's own screens rather than from a
      // content pack, so their authors correctly wrote no copy for them, and
      // reached through `JourneyScreenHost` they are exactly what an unwritten
      // screen looks like.
      final cancer = JourneyBuilder.forArea(bundle, bundle.area('cancer')!);
      final screen = cancer.awaitingCopy.first;
      await pump(
        tester,
        JourneyScreenHost(
          screen: screen,
          journey: cancer,
          onNavigate: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UnwrittenScreen), findsOneWidget);

      // The slot specs are the point of the screen: a writer has to be able to
      // read what this screen owes. They sit below the gap banner and the
      // screen's provenance, so finding them means scrolling — which is fine,
      // and is why this asserts presence rather than first-screenful position.
      final slot = screen.archetype!.slots.keys.first;
      await tester.scrollUntilVisible(
        find.textContaining(slot),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining(slot), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a BreatheFree screen renders its approved artwork',
        (tester) async {
      // The 23 screens that used to render as stubs. They are the most
      // reviewed designs in the product, and the shell now shows them rather
      // than claiming they are missing.
      final breatheFree =
          JourneyBuilder.forArea(bundle, bundle.area('tobacco')!);
      final screen = breatheFree.screen('S05')!;
      expect(screen.readiness, JourneyReadiness.artwork);

      await pump(
        tester,
        JourneyScreenHost(
          screen: screen,
          journey: breatheFree,
          onNavigate: (_) {},
        ),
      );
      await tester.pump();

      expect(find.byType(ArtworkScreen), findsOneWidget);
      expect(find.byType(UnwrittenScreen), findsNothing);
      // The real image, at the path the approved catalogue gives it.
      expect(
        tester
            .widgetList<Image>(find.byType(Image))
            .whereType<Image>()
            .isNotEmpty,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unbuilt archetype is not faked', (tester) async {
      // This used to be Cancer's `due_record`: an area with no product, no
      // copy and an archetype nobody had built, so there was nothing to draw
      // and the screen had to say so rather than invent a UI for it.
      //
      // No screen in the app is in that state any longer. All eleven areas
      // have a product, and every archetype those products name now exists —
      // `due_record` among them. `JourneyReadiness.awaitingArchetype` is
      // unreachable from the shipped data, which is asserted directly in
      // `test/tether_bundle_test.dart`.
      //
      // The arm is still live code in `JourneyScreenHost`, and it is the arm
      // that runs the first time somebody pins an archetype before building
      // it. Losing its only test at the moment the data stopped producing it
      // would mean it is never run again until a real screen depends on it. So
      // the screen is constructed here instead: a journey screen with no
      // content, no artwork and an archetype id the library does not define,
      // which is precisely the state the renderer exists for.
      final cancer = JourneyBuilder.forArea(bundle, bundle.area('cancer')!);
      expect(
        bundle.archetypes.containsKey('not_an_archetype'),
        isFalse,
        reason: 'this test needs an id the library genuinely does not define',
      );

      const screen = JourneyScreen(
        id: 'cancer.not_an_archetype',
        archetypeId: 'not_an_archetype',
        route: '/cancer/not_an_archetype',
        phase: 0,
        origin: JourneyOrigin.areaSpecific,
        archetype: null,
        content: null,
        rationale: 'Pinned by a product before anybody drew it.',
        isShell: false,
        isProposed: true,
      );
      expect(screen.readiness, JourneyReadiness.awaitingArchetype);

      await pump(
        tester,
        JourneyScreenHost(
          screen: screen,
          journey: cancer,
          onNavigate: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UnbuiltScreen), findsOneWidget);
      expect(find.byType(ContentScreen), findsNothing);
      expect(find.byType(UnwrittenScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('every unreviewed screen shows the notice', (tester) async {
      // The safety property the whole supplement rests on. Ten of LookUp's
      // screens were written in this repository and reviewed by nobody; if one
      // of them could render without saying so, a reader would have no way to
      // tell signed-off wording from wording invented to fill a gap.
      final unreviewed = lookup.screens.where(
        (screen) =>
            screen.content?.provenance == ContentProvenance.supplement,
      );
      expect(unreviewed, hasLength(10));

      for (final screen in unreviewed) {
        await pump(
          tester,
          JourneyScreenHost(
            screen: screen,
            journey: lookup,
            onNavigate: (_) {},
          ),
        );
        await tester.pump();
        expect(
          find.text('NOT CLINICALLY REVIEWED'),
          findsOneWidget,
          reason: '${screen.id} rendered unreviewed copy with no notice',
        );
      }
    });

    testWidgets('a bundle-authored screen shows no notice', (tester) async {
      await pump(
        tester,
        JourneyScreenHost(
          screen: lookup.screen('S12')!,
          journey: lookup,
          onNavigate: (_) {},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('NOT CLINICALLY REVIEWED'), findsNothing);
    });

    testWidgets('the intercept renders despite its unpromoted archetype',
        (tester) async {
      // S22 is the case that pins the readiness ordering: authored copy, no
      // archetype. It is the most finished screen in the product and must not
      // render as a stub.
      final intercept = lookup.screen('S22')!;
      expect(intercept.archetype, isNull);

      await pump(
        tester,
        JourneyScreenHost(
          screen: intercept,
          journey: lookup,
          onNavigate: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ContentScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('deep links resolve', () {
    Route<Object?>? route(String name, TetherSession state) =>
        TetherRouter.onGenerateRoute(RouteSettings(name: name), state);

    test('a product path prefers the program that can draw it', () {
      // Both BreatheFree and LookUp pin `/progress`. BreatheFree sorts first in
      // the catalogue but its screen is artwork reached another way, so the
      // path has to land on LookUp's authored screen rather than on whichever
      // area happens to come first.
      final state = session();
      expect(route('/progress', state), isNotNull);
      expect(route('/today', state), isNotNull);
      expect(route('/rescue/active', state), isNotNull);
    });

    test('an explicit program path reaches that program', () {
      final state = session();
      expect(route('/program/tobacco', state), isNotNull);
      expect(route('/program/tobacco/S05', state), isNotNull);
      expect(route('/program/cancer', state), isNotNull);
    });

    test('a bad program path fails visibly rather than silently', () {
      final state = session();
      // Still a route — it renders a named error — but never null, because
      // null falls through to onUnknownRoute and loses which link was wrong.
      expect(route('/program/nonsense', state), isNotNull);
      expect(route('/program/tobacco/S99', state), isNotNull);
      // A name matching nothing at all is left for onUnknownRoute.
      expect(route('/not-a-route-anywhere', state), isNull);
    });
  });

  group('every program has an overview', () {
    for (final areaId in const [
      'tobacco',
      'metabolic',
      'cancer',
      'cardiovascular',
      'nutrition',
      'respiratory',
      'kidney_liver',
      'behavioral',
      'preventive',
      'aging',
      'digital',
    ]) {
      testWidgets(areaId, (tester) async {
        final journey = JourneyBuilder.forArea(bundle, bundle.area(areaId)!);
        await pump(tester, ProgramOverviewScreen(journey: journey));
        await tester.pumpAndSettle();
        expect(find.byType(ProgramOverviewScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('all 237 screens across all eleven programs build', (tester) async {
    // The one test that would have caught a slot combination nobody drew by
    // hand. It asserts nothing about how a screen looks — only that asking for
    // it does not throw.
    var built = 0;
    final failures = <String>[];

    for (final journey in JourneyBuilder.all(bundle)) {
      for (final screen in journey.screens) {
        try {
          await pump(
            tester,
            JourneyScreenHost(
              screen: screen,
              journey: journey,
              onNavigate: (_) {},
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));
          final error = tester.takeException();
          if (error != null) {
            failures.add('${journey.area.id}/${screen.id}: $error');
          } else {
            built++;
          }
        } catch (error) {
          failures.add('${journey.area.id}/${screen.id}: $error');
        }
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
    expect(built, 237);
  });
}
