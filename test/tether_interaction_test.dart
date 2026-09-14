import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_health/tether/data/bundle_loader.dart';
import 'package:tether_health/tether/data/design_bundle.dart';
import 'package:tether_health/tether/journey/journey.dart';
import 'package:tether_health/tether/router/tether_router.dart';
import 'package:tether_health/tether/screens/journey_screen_host.dart';
import 'package:tether_health/tether/state/tether_scope.dart';
import 'package:tether_health/tether/widgets/call_affordance.dart';
import 'package:tether_health/tether/state/tether_session.dart';
import 'package:tether_health/tether/tether_app.dart';

import 'tether_bundle_test.dart' show DiskAssetBundle;

/// Every control on every authored screen, pressed.
///
/// The screens build — `tether_app_test.dart` proves that for all 236. What it
/// does not prove is that anything *happens* when a person touches them, and a
/// button that renders beautifully and does nothing is worse than one that is
/// visibly disabled: the person believes they acted.
///
/// So this file taps. Every footer button, every tappable card, every chip,
/// every option, on all 34 of LookUp's screens, and asserts the specific thing
/// that control was supposed to do.
void main() {
  late DesignBundle bundle;
  late Journey lookup;

  setUpAll(() async {
    bundle = await BundleLoader.load(bundle: DiskAssetBundle());
    lookup = JourneyBuilder.forArea(bundle, bundle.area('digital')!);
  });

  /// Pumps one journey screen and records where it tries to navigate.
  Future<List<String>> pumpScreen(
    WidgetTester tester,
    JourneyScreen screen, {
    TetherSession? state,
  }) async {
    final visited = <String>[];
    final active = state ?? TetherSession(bundle: bundle);
    await tester.pumpWidget(
      TetherScope(
        session: active,
        child: MaterialApp(
          theme: TetherTheme.light(),
          home: JourneyScreenHost(
            screen: screen,
            journey: lookup,
            onNavigate: visited.add,
          ),
          onGenerateRoute: (settings) =>
              TetherRouter.onGenerateRoute(settings, active),
        ),
      ),
    );
    await tester.pump();
    return visited;
  }

  group('footer buttons', () {
    testWidgets('every one navigates where its content says', (tester) async {
      final broken = <String>[];

      for (final screen in lookup.screens) {
        final content = screen.content;
        if (content == null) continue;

        for (var i = 0; i < content.actions.length; i++) {
          final action = content.actions[i];
          final visited = await pumpScreen(tester, screen);

          final button = find.widgetWithText(FilledButton, action.label);
          if (button.evaluate().isEmpty) {
            broken.add('${screen.id} action $i "${action.label}" not rendered');
            continue;
          }

          await tester.tap(button.first, warnIfMissed: false);
          await tester.pump();

          if (visited.isEmpty) {
            broken.add(
              '${screen.id} action $i "${action.label}" -> ${action.to} '
              'did nothing',
            );
          } else if (visited.single != action.to) {
            broken.add(
              '${screen.id} action $i went to ${visited.single}, '
              'expected ${action.to}',
            );
          }
        }
      }

      expect(broken, isEmpty, reason: broken.join('\n'));
    });
  });

  group('tappable cards', () {
    testWidgets('a card with a destination navigates to it', (tester) async {
      final broken = <String>[];

      for (final screen in lookup.screens) {
        final content = screen.content;
        if (content == null) continue;

        for (var i = 0; i < content.blocks.length; i++) {
          final block = content.blocks[i];
          final target = block.to;
          if (target == null) continue;

          // Located by its own words rather than by index. Most of these cards
          // are below the fold, and a ListView does not build what is not on
          // screen — tapping by index would be tapping whatever happens to be
          // visible.
          final label = switch (block) {
            CardBlock(:final title?) => title,
            CardBlock(:final body?) => body,
            _ => null,
          };
          if (label == null) {
            broken.add('${screen.id} block $i -> $target has no label to find');
            continue;
          }

          final visited = await pumpScreen(tester, screen);
          final text = find.text(label);
          await tester.scrollUntilVisible(
            text,
            200,
            scrollable: find.byType(Scrollable).first,
          );

          final card = find.ancestor(of: text, matching: find.byType(InkWell));
          if (card.evaluate().isEmpty) {
            broken.add(
              '${screen.id} block $i "$label" -> $target is not tappable',
            );
            continue;
          }

          // The text, not the card. A card whose centre has scrolled past the
          // bottom of the viewport would take the tap at coordinates that land
          // on the action button underneath it, and the test would report a
          // navigation that a person could never trigger.
          // Bounded pumps, never pumpAndSettle. Three of these screens run a
          // countdown — the rescue timer and the intercept's eight seconds —
          // and a periodic timer that rebuilds every second means the tree
          // never reaches a quiet frame. pumpAndSettle would spin until it
          // timed out.
          await tester.ensureVisible(text);
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(text.first, warnIfMissed: false);
          await tester.pump();

          if (!visited.contains(target)) {
            broken.add(
              '${screen.id} block $i "$label" -> $target never navigated '
              '(went to $visited)',
            );
          }
        }
      }

      expect(broken, isEmpty, reason: broken.join('\n'));
    });
  });

  group('answers are recorded', () {
    testWidgets('tapping a chip toggles and stores it', (tester) async {
      // S13's symptom chips arrive with two already lit. Tapping a lit one
      // must turn it off — the bug this guards against is a block that starts
      // empty in the session, where the first tap on a lit chip lights it
      // again and the person cannot deselect.
      final screen = lookup.screen('S13')!;
      final state = TetherSession(bundle: bundle);
      await pumpScreen(tester, screen, state: state);

      final blocks = screen.content!.blocks;
      final index = blocks.indexWhere(
        (block) => block is CardBlock && block.selected.isNotEmpty,
      );
      expect(index, isNot(-1), reason: 'S13 should ship with a lit chip');

      final block = blocks[index] as CardBlock;
      final lit = block.selected.first;
      expect(
        state.chipSelection(lookup.area.id, screen.id, index, block.selected),
        contains(lit),
      );

      await tester.tap(find.text(block.chips[lit]), warnIfMissed: false);
      await tester.pump();

      expect(
        state.answersFor(lookup.area.id, screen.id).chips[index],
        isNot(contains(lit)),
        reason: 'tapping a lit chip did not turn it off',
      );
    });

    testWidgets('choosing an option clears the others', (tester) async {
      final screen = lookup.screen('S07')!;
      final state = TetherSession(bundle: bundle);
      await pumpScreen(tester, screen, state: state);

      final index = screen.content!.blocks
          .indexWhere((block) => block is OptionsBlock);
      final block = screen.content!.blocks[index] as OptionsBlock;
      expect(block.items.length, greaterThan(1));

      await tester.tap(find.text(block.items.last.title), warnIfMissed: false);
      await tester.pump();

      expect(
        state.answersFor(lookup.area.id, screen.id).option[index],
        block.items.length - 1,
      );
    });

    testWidgets('a slider records where it was dragged', (tester) async {
      final screen = lookup.screen('S17')!;
      final state = TetherSession(bundle: bundle);
      await pumpScreen(tester, screen, state: state);

      final index =
          screen.content!.blocks.indexWhere((block) => block is SliderBlock);
      final before = state.answersFor(lookup.area.id, screen.id).slider[index];

      await tester.drag(find.byType(Slider).first, const Offset(-120, 0));
      await tester.pump();

      expect(
        state.answersFor(lookup.area.id, screen.id).slider[index],
        isNot(before),
      );
    });

    testWidgets('typing is kept', (tester) async {
      final screen = lookup.screen('S09')!;
      final state = TetherSession(bundle: bundle);
      await pumpScreen(tester, screen, state: state);

      final index =
          screen.content!.blocks.indexWhere((block) => block is InputBlock);
      await tester.enterText(find.byType(TextField).first, 'My own reason.');
      await tester.pump();

      expect(
        state.answersFor(lookup.area.id, screen.id).text[index],
        'My own reason.',
      );
    });
  });

  group('no control is a dead end', () {
    test('every pill on a card that goes nowhere is a call or a label', () {
      // A pill is drawn by the reference renderer as a selected chip, which
      // reads as a button. Fifteen of the twenty-three sit on a card that
      // navigates, so the promise is kept. The other eight kept nothing:
      // pressing them did exactly nothing, and two of them said "Call 988"
      // and "Call 911".
      //
      // The renderer now splits them — see `_Pill` — and this is the list it
      // has to keep splitting correctly.
      final calls = <String>[];
      final labels = <String>[];
      for (final screen in lookup.screens) {
        final content = screen.content;
        if (content == null) continue;
        for (final block in content.blocks) {
          if (block is! CardBlock) continue;
          final pill = block.pill;
          if (pill == null || block.to != null) continue;
          if (CallAffordance.numberIn(pill) != null) {
            calls.add('${screen.id}: "$pill"');
          } else {
            labels.add('${screen.id}: "$pill"');
          }
        }
      }

      expect(calls, ['S27: "Call 988"', 'SH6: "Call 911"']);
      expect(labels, hasLength(6));
    });

    testWidgets('a call pill offers the number', (tester) async {
      // The single most important control in the product. It was dead.
      final screen = lookup.screen('S27')!;
      await pumpScreen(tester, screen);

      await tester.tap(find.text('Call 988'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('988'), findsWidgets);

      // The clipboard is mocked rather than read back. `Clipboard.getData`
      // goes out to a platform channel that the test harness does not answer,
      // and waiting on a reply that never arrives hangs the run.
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

      await tester.tap(find.widgetWithText(FilledButton, 'Copy number'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(copied, '988');
    });

    test('the call pattern does not match a person', () {
      // "Call Jordan" names a supporter this build holds no number for. A
      // pattern loose enough to match it would put a dialog in front of
      // somebody promising a call it cannot offer.
      expect(CallAffordance.numberIn('Call 988'), '988');
      expect(CallAffordance.numberIn('Call 911'), '911');
      expect(CallAffordance.numberIn('Call 1-800-784-8669'), '1-800-784-8669');
      expect(CallAffordance.numberIn('Call Jordan'), isNull);
      expect(CallAffordance.numberIn('Open Rescue'), isNull);
      expect(CallAffordance.numberIn('Set it up'), isNull);
    });
  });
}
