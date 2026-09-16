import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_health/tether/data/bundle_loader.dart';
import 'package:tether_health/tether/data/design_bundle.dart';
import 'package:tether_health/tether/router/tether_router.dart';
import 'package:tether_health/tether/screens/shell/programs_home_screen.dart';
import 'package:tether_health/tether/screens/shell/remedies_screen.dart';
import 'package:tether_health/tether/screens/shell/remedy_screen.dart';
import 'package:tether_health/tether/screens/shell/shell_routes.dart';
import 'package:tether_health/tether/state/tether_scope.dart';
import 'package:tether_health/tether/state/tether_session.dart';
import 'package:tether_health/tether/tether_app.dart';

import 'tether_bundle_test.dart' show DiskAssetBundle;

/// The remedy library.
///
/// Most of what is worth testing here is not layout. It is the set of promises
/// the library makes about its own content: that nothing in it is bound to a
/// program, that every remedy admits what it does not do, and that the stop
/// rule is drawn before the instructions rather than after them. Those are the
/// properties that make a list of health advice safe to show to somebody whose
/// diagnosis this app does not know.
void main() {
  late DesignBundle bundle;

  setUpAll(() async {
    bundle = await BundleLoader.load(bundle: DiskAssetBundle());
  });

  /// A viewport tall enough to hold a whole screen at once.
  ///
  /// `TetherPage` draws its body in a lazy `ListView`, so anything below the
  /// fold is never built and `find.text` cannot see it. Scrolling each
  /// assertion into view would work and would also mean a test that failed
  /// because a card moved, rather than because it was missing. Making the
  /// window tall keeps the assertions about content.
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pump(WidgetTester tester, Widget screen) async {
    useTallViewport(tester);
    final session = TetherSession(bundle: bundle);
    await tester.pumpWidget(
      TetherScope(
        session: session,
        child: MaterialApp(
          theme: TetherTheme.light(),
          home: screen,
          onGenerateRoute: (settings) =>
              TetherRouter.onGenerateRoute(settings, session),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the library as data', () {
    test('loads', () {
      expect(bundle.remedies, isNotEmpty);
    });

    test('every remedy says what it does not do', () {
      // The boundary is the one field with no honest default. A remedy that
      // did not carry one would render a card with a heading and no text,
      // which reads as an oversight rather than as a claim — and the claim is
      // the point.
      for (final remedy in bundle.remedies) {
        expect(
          remedy.boundary,
          isNotEmpty,
          reason: '${remedy.id} has no boundary',
        );
      }
    });

    test('every remedy has steps and a summary somebody can act on', () {
      for (final remedy in bundle.remedies) {
        expect(remedy.steps, isNotEmpty, reason: remedy.id);
        expect(remedy.summary, isNotEmpty, reason: remedy.id);
        expect(remedy.helpsWith, isNotEmpty, reason: remedy.id);
      }
    });

    test('every physically exerting remedy carries a stop rule', () {
      // Not every remedy needs one — writing questions down before an
      // appointment has no failure mode, and inventing a warning for it would
      // teach people to skim past the warnings that matter. But anything with
      // a clock on it asks somebody to keep going for a set time, and that is
      // exactly when a person ignores their own body.
      for (final remedy in bundle.remedies.where((r) => r.isTimed)) {
        expect(
          remedy.hasStopRule,
          isTrue,
          reason: '${remedy.id} is timed but never says when to stop',
        );
      }
    });

    test('no remedy is bound to a program', () {
      // The clinical constraint, asserted against the raw field list rather
      // than the model: `Remedy` has no `areaId`, so the way this rule gets
      // broken in future is somebody adding one. Two remedies with the same
      // id, or an id that names an area, would be the first symptom.
      final ids = bundle.remedies.map((remedy) => remedy.id).toList();
      expect(ids.toSet(), hasLength(ids.length), reason: 'duplicate remedy id');

      final areaIds = bundle.areas.map((area) => area.id).toSet();
      for (final id in ids) {
        expect(
          areaIds.contains(id),
          isFalse,
          reason: '$id is named after an area, which suggests it is scoped to '
              'one — see design/remedies-clinical-review.md',
        );
      }
    });

    test('nothing in the library reads like a dose or a target', () {
      // A blunt guard against the failure this whole design exists to avoid:
      // somebody adding "drink 2 litres a day" or "aim for 10000 steps" to a
      // file that is shown to people on dialysis and people with angina alike.
      final forbidden = RegExp(
        r'\b(\d+\s*(mg|ml|litre|liters?|litres?|grams?|g)\b|'
        r'\d{3,}\s*steps|\bdose|\bdosage|\btablets?\b)',
        caseSensitive: false,
      );
      for (final remedy in bundle.remedies) {
        final text = [
          remedy.summary,
          remedy.boundary,
          remedy.stopIf,
          ...remedy.steps,
        ].join(' ');
        expect(
          forbidden.hasMatch(text),
          isFalse,
          reason: '${remedy.id} contains something that reads as a quantity',
        );
      }
    });
  });

  group('the library screen', () {
    testWidgets('lists every remedy', (tester) async {
      await pump(tester, const RemediesScreen());
      for (final remedy in bundle.remedies) {
        expect(
          find.text(remedy.title),
          findsOneWidget,
          reason: '${remedy.id} is missing from the library',
        );
      }
    });

    testWidgets('opens one', (tester) async {
      await pump(tester, const RemediesScreen());
      final first = bundle.remedies.first;

      await tester.tap(find.text(first.title));
      await tester.pumpAndSettle();

      expect(find.byType(RemedyScreen), findsOneWidget);
      expect(find.text(first.steps.first), findsOneWidget);
    });

    testWidgets('says the library is not treatment', (tester) async {
      await pump(tester, const RemediesScreen());
      expect(find.text('These are not treatment'), findsOneWidget);
    });
  });

  group('one remedy', () {
    testWidgets('draws the stop rule above the steps', (tester) async {
      // The safety property. A warning underneath the instructions is a
      // warning the person reads after they have already started, so this
      // asserts vertical order on screen rather than order in a list —
      // reordering the children is exactly the change that would break it.
      final timed = bundle.remedies.firstWhere((r) => r.hasStopRule);
      await pump(tester, RemedyScreen(remedy: timed));

      final stopHeading = tester.getTopLeft(find.text('Stop if'));
      final firstStep = tester.getTopLeft(find.text(timed.steps.first));

      expect(
        stopHeading.dy,
        lessThan(firstStep.dy),
        reason: 'the stop rule for ${timed.id} is below its instructions',
      );
    });

    testWidgets('shows the boundary', (tester) async {
      final remedy = bundle.remedies.first;
      await pump(tester, RemedyScreen(remedy: remedy));
      expect(find.text('What this does not do'), findsOneWidget);
      expect(find.text(remedy.boundary), findsOneWidget);
    });

    testWidgets('draws no stop card when there is no rule', (tester) async {
      final open = bundle.remedies.where((r) => !r.hasStopRule);
      if (open.isEmpty) return;
      await pump(tester, RemedyScreen(remedy: open.first));
      expect(find.text('Stop if'), findsNothing);
    });

    testWidgets('numbers every step', (tester) async {
      final remedy = bundle.remedies.first;
      await pump(tester, RemedyScreen(remedy: remedy));
      for (var i = 0; i < remedy.steps.length; i++) {
        expect(find.text('${i + 1}'), findsOneWidget);
      }
    });
  });

  group('addressed by name', () {
    // `/remedies/<id>` is what a notification would deep-link to at the moment
    // somebody needs it. It used to resolve to nothing: the library pushed the
    // screen with the object and only *labelled* the route with this path, so
    // the label named a route that did not exist. MaterialApp walks a deep
    // link segment by segment and falls back to `/` when a segment cannot be
    // built, so the app opened on the home screen — silently, without even
    // reaching the unknown-route handler.
    testWidgets('a deep link opens the remedy', (tester) async {
      final remedy = bundle.remedies.first;
      await pump(tester, const RemediesScreen());

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(navigator.pushNamed(ShellRoutes.remedy(remedy.id)));
      await tester.pumpAndSettle();

      expect(find.byType(RemedyScreen), findsOneWidget);
      expect(find.text(remedy.steps.first), findsOneWidget);
    });

    testWidgets('an unknown id says so rather than going quiet', (tester) async {
      await pump(tester, const RemediesScreen());

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(navigator.pushNamed(ShellRoutes.remedy('no_such_practice')));
      await tester.pumpAndSettle();

      expect(find.byType(RemedyScreen), findsNothing);
      expect(find.textContaining('no_such_practice'), findsOneWidget);
    });

    testWidgets('tapping a card uses that same route', (tester) async {
      // The two paths are now one. If this ever diverges again, the deep link
      // is what breaks, and it breaks silently.
      final remedy = bundle.remedies.first;
      await pump(tester, const RemediesScreen());

      await tester.tap(find.text(remedy.title));
      await tester.pumpAndSettle();

      final route = ModalRoute.of(
        tester.element(find.byType(RemedyScreen)),
      );
      expect(route?.settings.name, ShellRoutes.remedy(remedy.id));
    });
  });

  group('the way in', () {
    testWidgets('the home screen offers the library', (tester) async {
      await pump(tester, const ProgramsHomeScreen());
      expect(find.text('Things that help'), findsOneWidget);
    });

    testWidgets('and hides it when there are no remedies', (tester) async {
      // A row that leads to an empty page is worse than no row. The supplement
      // is optional, so this is a real configuration and not a hypothetical.
      final empty = DesignBundle(
        areas: bundle.areas,
        archetypes: bundle.archetypes,
        safeguards: bundle.safeguards,
        shell: bundle.shell,
        products: bundle.products,
        content: bundle.content,
      );
      useTallViewport(tester);
      final session = TetherSession(bundle: empty);
      await tester.pumpWidget(
        TetherScope(
          session: session,
          child: MaterialApp(
            theme: TetherTheme.light(),
            home: const ProgramsHomeScreen(),
            onGenerateRoute: (settings) =>
                TetherRouter.onGenerateRoute(settings, session),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(empty.remedies, isEmpty);
      expect(find.text('Things that help'), findsNothing);
    });
  });
}
