import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_health/tether/data/bundle_loader.dart';
import 'package:tether_health/tether/data/design_bundle.dart';
import 'package:tether_health/tether/journey/journey.dart';
import 'package:tether_health/tether/router/tether_router.dart';
import 'package:tether_health/tether/screens/content_screen.dart';
import 'package:tether_health/tether/screens/shell/crisis_route_screen.dart';
import 'package:tether_health/tether/screens/shell/shell_routes.dart';
import 'package:tether_health/tether/state/tether_scope.dart';
import 'package:tether_health/tether/theme/tether_tokens.dart';
import 'package:tether_health/tether/state/tether_session.dart';
import 'package:tether_health/tether/tether_app.dart';

import 'tether_bundle_test.dart' show DiskAssetBundle;

/// Whole journeys, walked through the real router.
///
/// The per-screen tests press one control on one screen in isolation. What
/// they cannot see is the thing a person actually does: five screens in a row,
/// then back. Routing, the back stack and state carried between screens only
/// go wrong once there is more than one screen.
void main() {
  late DesignBundle bundle;
  late Journey lookup;

  setUpAll(() async {
    bundle = await BundleLoader.load(bundle: DiskAssetBundle());
    lookup = JourneyBuilder.forArea(bundle, bundle.area('digital')!);
  });

  /// Boots the app at [route] with a real Navigator behind it.
  Future<TetherSession> boot(WidgetTester tester, String route) async {
    final session = TetherSession(bundle: bundle);
    await tester.pumpWidget(
      TetherScope(
        session: session,
        child: MaterialApp(
          // A fresh key per boot, so a second call in the same test really
          // restarts. Without it Flutter reuses the existing MaterialApp
          // element, the Navigator keeps its stack, and `initialRoute` is
          // ignored — the test would then assert against the previous screen
          // and pass or fail for the wrong reason.
          key: UniqueKey(),
          theme: TetherTheme.light(),
          initialRoute: route,
          onGenerateRoute: (settings) =>
              TetherRouter.onGenerateRoute(settings, session),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return session;
  }

  /// The id of the screen a person is actually looking at.
  ///
  /// Hit-testable, not simply present. During and just after a pop both routes
  /// are in the tree, and taking the last one found would name the screen that
  /// is on its way out — which is how a broken back stack would pass a test.
  String? currentScreen(WidgetTester tester) {
    final visible = find.byType(ContentScreen).hitTestable();
    final screens = tester.widgetList<ContentScreen>(visible);
    return screens.isEmpty ? null : screens.last.screen.id;
  }

  Future<void> press(WidgetTester tester, String label) async {
    final button = find.widgetWithText(FilledButton, label);
    // Actions sit below the scrolling body, so they are normally on screen
    // already — but a screen can be short enough that the body does not fill
    // the viewport, and scrolling first costs nothing either way.
    final scrollable = find.byType(Scrollable);
    if (button.evaluate().isEmpty && scrollable.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(button, 200,
          scrollable: scrollable.first);
    }
    expect(button, findsWidgets, reason: 'no button labelled "$label"');
    await tester.ensureVisible(button.first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(button.first, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('the rescue flow runs end to end', (tester) async {
    // S17 → S18 → S19 → S20 → S21 → S12. This is the path the product exists
    // for, and it is five pushes deep, so it is also where a broken back stack
    // would first hurt.
    await boot(tester, '/program/digital/S17');
    expect(currentScreen(tester), 'S17');

    await press(tester, 'Find me a tool');
    expect(currentScreen(tester), 'S18');

    await press(tester, 'Start this tool');
    expect(currentScreen(tester), 'S19');

    await press(tester, 'End early');
    expect(currentScreen(tester), 'S20');

    await press(tester, 'Save and continue');
    expect(currentScreen(tester), 'S21');

    await press(tester, 'Back to today');
    expect(currentScreen(tester), 'S12');

    expect(tester.takeException(), isNull);
  });

  testWidgets('back unwinds the flow one screen at a time', (tester) async {
    await boot(tester, '/program/digital/S17');
    await press(tester, 'Find me a tool');
    await press(tester, 'Start this tool');
    expect(currentScreen(tester), 'S19');

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(currentScreen(tester), 'S18');

    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(currentScreen(tester), 'S17');
  });

  testWidgets('an answer survives moving between screens', (tester) async {
    // The rescue recheck shows what the person said before. If the session did
    // not carry the first rating forward, "you started at 7" would be a
    // sentence with nothing behind it.
    final session = await boot(tester, '/program/digital/S17');

    await tester.drag(find.byType(Slider).first, const Offset(-100, 0));
    await tester.pump();
    // Read back under the program the route named, because that is the key:
    // `digital` and `behavioral` both run LookUp and both contain `S17`.
    final recorded = session.answersFor('digital', 'S17').slider[0];
    expect(recorded, isNotNull);

    await press(tester, 'Find me a tool');
    await press(tester, 'Start this tool');
    await press(tester, 'End early');
    expect(currentScreen(tester), 'S20');

    expect(session.answersFor('digital', 'S17').slider[0], recorded);
  });

  testWidgets('the crisis route is one tap from Today', (tester) async {
    // `docs-testing.md`, test 2: "You need to talk to a person right now" must
    // reach the crisis card "without scrolling past anything". On S12 the
    // crisis card is the first block, and this checks it is still both first
    // and one tap from the home screen.
    final today = lookup.screen('S12')!.content!;
    final first = today.blocks.first;
    expect(first, isA<CardBlock>());
    expect((first as CardBlock).to, 'SH6');

    await boot(tester, '/program/digital/S12');
    expect(currentScreen(tester), 'S12');

    await tester.tap(find.text(first.title!), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byType(CrisisRouteScreen),
      findsOneWidget,
      reason: 'the crisis card on Today did not reach the crisis route',
    );
  });

  testWidgets('the crisis route is the same screen from anywhere',
      (tester) async {
    // `one_crisis_route`. Reached from a program screen and from the shell, it
    // must be the one screen, not a per-program copy.
    await boot(tester, ShellRoutes.crisis);
    expect(find.byType(CrisisRouteScreen), findsOneWidget);

    await boot(tester, '/program/digital/S27');
    await press(tester, 'Preview what would be sent');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the onboarding flow reaches the plan', (tester) async {
    // S01 → S02 → S03 → S05 → S07. S02 is the screen the shipped content
    // skipped; this walks the corrected path.
    await boot(tester, '/program/digital/S01');
    expect(currentScreen(tester), 'S01');

    await press(tester, 'Get started');
    expect(currentScreen(tester), 'S02',
        reason: 'welcome no longer reaches the why screen');

    final onward = lookup.screen('S02')!.content!.actions.first;
    await press(tester, onward.label);
    expect(currentScreen(tester), 'S03');

    await press(tester, 'Agree and continue');
    expect(currentScreen(tester), 'S05');
  });

  testWidgets('a partly written program opens without a dead screen',
      (tester) async {
    // Cancer used to have no product and no copy at all, and every screen
    // still had to open. WorthAsking now supplies its fourteen, eight of them
    // with copy and six of them the shell's — so the mix this walks is
    // authored screens and unwritten ones in one journey, which is the state
    // every programme except LookUp and BreatheFree is in. Opening a screen
    // must not depend on somebody having written it.
    final cancer = JourneyBuilder.forArea(bundle, bundle.area('cancer')!);
    for (final screen in cancer.screens.take(6)) {
      await boot(tester, '/program/cancer/${screen.id}');
      expect(tester.takeException(), isNull, reason: screen.id);
    }
  });

  testWidgets('the intercept renders dark, with its one lime button',
      (tester) async {
    // S22 is the only dark screen and carries the only lime button in the
    // product. Both exist so that the moment a shielded app is opened does not
    // look like every other screen — if either regressed to the default light
    // chrome nothing would throw, and nobody would notice from a test that
    // only checked the screen built.
    await boot(tester, '/program/digital/S22');

    final content = lookup.screen('S22')!.content!;
    expect(content.dark, isTrue);
    expect(content.actions.any((action) => action.kind == 'lime'), isTrue);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, TetherColors.ink);

    final lime = content.actions.firstWhere((a) => a.kind == 'lime');
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, lime.label).first,
    );
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{}),
      TetherColors.lime,
    );
  });

  testWidgets('a covered countdown stops ticking', (tester) async {
    // The rescue timer used to keep counting from underneath whatever was
    // pushed over it, rebuilding an invisible widget once a second for the
    // rest of the session.
    await boot(tester, '/program/digital/S19');
    await tester.pump(const Duration(seconds: 2));

    final before = tester.widget<Text>(
      find.descendant(
        of: find.byType(Semantics),
        matching: find.byWidgetPredicate(
          (widget) => widget is Text && int.tryParse(widget.data ?? '') != null,
        ),
      ).first,
    ).data;

    await press(tester, 'End early');
    expect(currentScreen(tester), 'S20');

    // Five seconds pass with S19 covered. Its number must not have moved.
    await tester.pump(const Duration(seconds: 5));

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(currentScreen(tester), 'S19');

    final after = tester.widget<Text>(
      find.descendant(
        of: find.byType(Semantics),
        matching: find.byWidgetPredicate(
          (widget) => widget is Text && int.tryParse(widget.data ?? '') != null,
        ),
      ).first,
    ).data;

    expect(
      int.parse(after!),
      greaterThanOrEqualTo(int.parse(before!) - 2),
      reason: 'the countdown kept running while it was covered',
    );
  });
}
