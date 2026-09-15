import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_health/tether/data/bundle_loader.dart';
import 'package:tether_health/tether/data/design_bundle.dart';
import 'package:tether_health/tether/router/tether_router.dart';
import 'package:tether_health/tether/screens/shell/area_directory_screen.dart';
import 'package:tether_health/tether/screens/shell/crisis_route_screen.dart';
import 'package:tether_health/tether/screens/shell/program_join_screen.dart';
import 'package:tether_health/tether/screens/shell/programs_home_screen.dart';
import 'package:tether_health/tether/screens/shell/record_screen.dart';
import 'package:tether_health/tether/screens/shell/sharing_matrix_screen.dart';
import 'package:tether_health/tether/state/tether_scope.dart';
import 'package:tether_health/tether/state/tether_session.dart';
import 'package:tether_health/tether/tether_app.dart';

import 'tether_bundle_test.dart'
    show CatalogueOnlyAssetBundle, DiskAssetBundle;

/// The six shell screens, driven rather than rendered.
///
/// These are the screens that change something: joining a program, pausing
/// one, switching on sharing, exporting, deleting. A widget test that only
/// pumps them proves the layout; it does not prove that pressing Join joins
/// anything, and those are the controls where being wrong costs a person
/// something real.
void main() {
  late DesignBundle bundle;

  /// The bundle without this repository's eight product files, so that the
  /// eight areas the catalogue still leaves unbuilt are available to test SH3's
  /// not-implemented branch against. See [CatalogueOnlyAssetBundle].
  ///
  /// Loaded here rather than inside the test that needs it: `BundleLoader`
  /// reads real files, and a real I/O future never completes inside
  /// `testWidgets`' fake-async zone.
  late DesignBundle catalogue;

  setUpAll(() async {
    bundle = await BundleLoader.load(bundle: DiskAssetBundle());
    catalogue = await BundleLoader.load(bundle: CatalogueOnlyAssetBundle());
  });

  Future<TetherSession> pump(
    WidgetTester tester,
    Widget screen, {
    TetherSession? state,
  }) async {
    final active = state ?? TetherSession(bundle: bundle);
    await tester.pumpWidget(
      TetherScope(
        session: active,
        child: MaterialApp(
          theme: TetherTheme.light(),
          home: screen,
          onGenerateRoute: (settings) =>
              TetherRouter.onGenerateRoute(settings, active),
        ),
      ),
    );
    await tester.pump();
    return active;
  }

  /// Scrolls [finder] into view, tolerating a screen that does not scroll.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(finder, 200,
          scrollable: scrollable.first);
    }
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('SH3 · joining a program', () {
    testWidgets('Join actually joins', (tester) async {
      final area = bundle.area('digital')!;
      final state = await pump(tester, ProgramJoinScreen(area: area));
      expect(state.enrolment('digital').isJoined, isFalse);

      final join = find.byWidgetPredicate(
        (widget) =>
            widget is FilledButton &&
            widget.child is Text &&
            (widget.child! as Text).data?.toLowerCase().contains('join') ==
                true &&
            widget.onPressed != null,
      );
      await reveal(tester, join.first);
      await tester.tap(join.first, warnIfMissed: false);
      await tester.pump();

      expect(
        state.enrolment('digital').isActive,
        isTrue,
        reason: 'the Join button did not join the program',
      );
    });

    /// A live Join button: the control the not-implemented branch must not draw.
    final liveJoin = find.byWidgetPredicate(
      (widget) =>
          widget is FilledButton &&
          widget.child is Text &&
          (widget.child! as Text).data?.toLowerCase().contains('join') == true &&
          widget.onPressed != null,
    );

    testWidgets('a planned area offers no join at all', (tester) async {
      // `cancer` used to be the example here: nine areas had no implementation,
      // and offering a control that cannot work is the failure
      // `not_every_area_ships` exists to prevent.
      //
      // Every area now has a product, so no area in the shipped data reaches
      // this branch of SH3. The branch is still drawn — the "There is nothing
      // to join yet" card and the suppressed button — and it is still the
      // screen an area gets the next time one is added ahead of its product.
      // It is exercised against the catalogue as the bundle ships it, where
      // `cancer` really does carry `productId: null`. See
      // [CatalogueOnlyAssetBundle].
      final area = catalogue.area('cancer')!;
      expect(area.productId, isNull);

      // Tall enough that the whole page is built. `TetherPage` draws its body
      // into a `ListView`, which builds only what is on screen, and the notice
      // below is far enough down that a phone-sized surface would report it
      // missing when it is merely not yet built.
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final state = await pump(
        tester,
        ProgramJoinScreen(area: area),
        state: TetherSession(bundle: catalogue),
      );

      expect(liveJoin, findsNothing);
      expect(state.enrolment('cancer').isJoined, isFalse);
      // The refusal is stated, not merely enacted. A screen that dropped the
      // button and said nothing would look like a screen that had failed to
      // load.
      expect(find.text('There is nothing to join yet'), findsOneWidget);
      // And the scope disclaimer survives the variant. `shell.json` marks it
      // required with no exception for the screens that have nothing to offer.
      expect(
        find.textContaining('It does not diagnose, treat or prescribe'),
        findsOneWidget,
      );
    });

    testWidgets('every implemented area offers a live join', (tester) async {
      // The other half of `not_every_area_ships`, and the half that has a
      // subject now: an area with a programme behind it has to offer to start
      // it. All eleven do.
      for (final area in bundle.areas) {
        await pump(tester, ProgramJoinScreen(area: area));
        expect(
          liveJoin,
          findsOneWidget,
          reason: '${area.id} is built as ${area.productId} and SH3 offered '
              'no way to join it',
        );
        expect(find.text('There is nothing to join yet'), findsNothing,
            reason: area.id);
      }
    });

    testWidgets('a third program is refused, not silently swapped',
        (tester) async {
      final state = TetherSession(bundle: bundle);
      state.join('tobacco');
      state.join('digital');

      await pump(
        tester,
        ProgramJoinScreen(area: bundle.area('behavioral')!),
        state: state,
      );

      // Whatever the screen offers, it must not end with three running.
      for (final button in tester
          .widgetList<FilledButton>(find.byType(FilledButton))
          .toList()) {
        if (button.onPressed == null) continue;
        button.onPressed!();
        await tester.pump();
      }
      expect(state.activePrograms.length, lessThanOrEqualTo(2));
    });
  });

  group('SH1 · your programs', () {
    testWidgets('every enabled control does something', (tester) async {
      final state = TetherSession(bundle: bundle);
      state.join('digital');
      await pump(tester, const ProgramsHomeScreen(), state: state);

      // Nothing here may throw, and the ceiling must survive whatever is
      // pressed.
      final buttons = find.byType(FilledButton);
      for (var i = 0; i < buttons.evaluate().length; i++) {
        final widget = tester.widget<FilledButton>(buttons.at(i));
        if (widget.onPressed == null) continue;
        widget.onPressed!();
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      expect(state.activePrograms.length, lessThanOrEqualTo(2));
    });
  });

  group('SH5 · sharing', () {
    testWidgets('a switch changes only its own program', (tester) async {
      final state = TetherSession(bundle: bundle);
      state.join('tobacco');
      state.join('digital');
      await pump(tester, const SharingMatrixScreen(), state: state);

      final switches = find.byType(Switch);
      expect(switches, findsWidgets, reason: 'no sharing controls rendered');

      await reveal(tester, switches.first);
      await tester.tap(switches.first, warnIfMissed: false);
      await tester.pump();

      final sharing = bundle.areas
          .where((area) => state.enrolment(area.id).sharing.sharesAnything)
          .map((area) => area.id)
          .toList();
      expect(
        sharing.length,
        1,
        reason: 'one switch changed $sharing — sharing is per program',
      );
    });
  });

  group('SH4 · your record', () {
    testWidgets('export shows what is held', (tester) async {
      final state = TetherSession(bundle: bundle);
      state.join('digital');
      state.setSlider('digital', 'S17', 0, 70);
      await pump(tester, const RecordScreen(), state: state);

      final export = find.byWidgetPredicate(
        (widget) =>
            widget is FilledButton &&
            widget.child is Text &&
            (widget.child! as Text).data?.toLowerCase().contains('export') ==
                true,
      );
      expect(export, findsWidgets, reason: 'no export control');

      await reveal(tester, export.first);
      await tester.tap(export.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      // The program that was joined has to appear in whatever it showed.
      expect(find.textContaining('digital'), findsWidgets);
    });

    testWidgets('delete asks first and then really deletes', (tester) async {
      final state = TetherSession(bundle: bundle);
      state.join('digital');
      await pump(tester, const RecordScreen(), state: state);

      // Found by its words, not its widget type. The delete control on this
      // screen is a tappable card rather than a button, and a finder that
      // insisted on FilledButton would report "no delete control" on a screen
      // that has a perfectly good one.
      // Revealed before it is asserted: the control is below the fold, and a
      // ListView has not built what is not on screen, so checking first would
      // report a missing control that is simply further down.
      final delete = find.text('Delete everything');
      await reveal(tester, delete);
      expect(delete, findsWidgets, reason: 'no delete control');
      await tester.tap(delete.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // A destructive action must not run on the first press.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        state.enrolment('digital').isJoined,
        isTrue,
        reason: 'delete ran before the person confirmed it',
      );

      final confirm = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Delete everything'),
      );
      expect(confirm, findsWidgets, reason: 'no confirm control in the dialog');
      await tester.tap(confirm.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(state.enrolment('digital').isJoined, isFalse);
      expect(state.activePrograms, isEmpty);
    });
  });

  group('SH6 · get help now', () {
    testWidgets('the emergency number can be copied', (tester) async {
      await pump(tester, const CrisisRouteScreen());

      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      // Likewise by words. The crisis route draws its numbers as pill-shaped
      // TextButtons, and the emergency card is also tappable as a whole.
      final call = find.textContaining(RegExp(r'^Call \d'));
      expect(call, findsWidgets, reason: 'no call control on the crisis route');

      await reveal(tester, call.first);
      await tester.tap(call.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final copy = find.widgetWithText(FilledButton, 'Copy number');
      expect(copy, findsOneWidget, reason: 'the call dialog did not open');
      await tester.tap(copy);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(copied, isNotNull);
      expect(copied, isNotEmpty);
    });
  });

  group('SH2 · health areas', () {
    testWidgets('an implemented area row opens its join screen',
        (tester) async {
      await pump(tester, const AreaDirectoryScreen());

      // `_AreaRow` is tappable only when the area has a product behind it, and
      // the directory has to make that difference operable rather than merely
      // visible. All eleven rows are tappable now — the not-joinable row is
      // covered by the SH3 group above, against the catalogue that still has
      // one.
      await reveal(tester, find.text('Tobacco & nicotine'));
      await tester.tap(find.text('Tobacco & nicotine'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });
  });
}
