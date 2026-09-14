import 'package:flutter_test/flutter_test.dart';
import 'package:tether_health/tether/data/bundle_loader.dart';
import 'package:tether_health/tether/data/design_bundle.dart';
import 'package:tether_health/tether/journey/journey.dart';

import 'tether_bundle_test.dart' show DiskAssetBundle;

void main() {
  late DesignBundle bundle;
  late Map<String, Journey> journeys;

  setUpAll(() async {
    bundle = await BundleLoader.load(bundle: DiskAssetBundle());
    journeys = {
      for (final journey in JourneyBuilder.all(bundle))
        journey.area.id: journey,
    };
  });

  test('all eleven areas produce a program', () {
    // This is the claim the whole shell rests on: the machinery is built once
    // and shaped to each area, and `areas.json` already declares each area's
    // screen list, so nine areas with no product file still have a journey.
    expect(journeys, hasLength(11));
    for (final journey in journeys.values) {
      expect(journey.screens, isNotEmpty, reason: journey.area.id);
      expect(journey.entry, isNotNull, reason: journey.area.id);
    }
  });

  test('every journey lands on the home archetype when it has one', () {
    for (final journey in journeys.values) {
      final hasHome =
          journey.screens.any((screen) => screen.archetypeId == 'home');
      if (!hasHome) continue;
      expect(
        journey.entry!.archetypeId,
        'home',
        reason: '${journey.area.id} opens somewhere other than its home',
      );
    }
  });

  test('screen ids and routes are unique inside a journey', () {
    for (final journey in journeys.values) {
      final ids = journey.screens.map((screen) => screen.id).toList();
      final routes = journey.screens.map((screen) => screen.route).toList();
      expect(ids.toSet(), hasLength(ids.length), reason: journey.area.id);
      expect(routes.toSet(), hasLength(routes.length), reason: journey.area.id);
    }
  });

  group('the two authored products', () {
    test('LookUp is complete: all 34 screens render', () {
      final journey = journeys['digital']!;
      expect(journey.isGenerated, isFalse);
      expect(journey.screens, hasLength(34));

      expect(journey.withReadiness(JourneyReadiness.authored), hasLength(34));
      expect(journey.awaitingCopy, isEmpty);
      expect(journey.awaitingArchetype, isEmpty);

      // S22 is the screen that pins the readiness ordering: finished copy,
      // and an archetype that was never promoted into the shared library.
      expect(journey.screen('S22')!.archetype, isNull);
      expect(journey.screen('S22')!.readiness, JourneyReadiness.authored);

      // S04 and S24 were the two unbuilt ones. They now have both an archetype
      // and copy, both proposed here rather than shipped.
      for (final id in ['S04', 'S24']) {
        expect(journey.screen(id)!.archetype, isNotNull, reason: id);
        expect(journey.screen(id)!.readiness, JourneyReadiness.authored,
            reason: id);
      }
    });

    test('the welcome screen reaches the why screen', () {
      // The `welcome` archetype declares its primary action goes to `why`, and
      // the shipped content sent it to `S03` instead, leaving `S02`
      // unreachable from the flow. `supplement.navigation.json` restores the
      // link. This asserts the fix applied, that it changed only the
      // destination, and that the step it skipped is still reached.
      final journey = journeys['digital']!;
      final welcome = journey.screen('S01')!.content!;

      expect(welcome.actions.first.to, 'S02');
      expect(welcome.actions.first.label, 'Get started');
      expect(journey.screen('S02')!.content!.actions.first.to, 'S03');

      // And the words are untouched: this is a routing fix, not an edit.
      expect(welcome.provenance, ContentProvenance.bundle);
      expect(welcome.headline, 'Your attention is yours to spend.');
    });

    test('LookUp has no dead ends', () {
      // The bundle's first acceptance test, run as a unit test: "no dead
      // ends, no screen with two competing primary actions, every screen
      // reachable from /today in three taps or fewer".
      expect(journeys['digital']!.deadEnds, isEmpty);
    });

    test('behavioral and digital share the one LookUp product', () {
      // Both areas name `lookup` as their product, so both get the same
      // journey. That is what the catalogue says; it is asserted here so the
      // duplication is a known property rather than a surprise.
      expect(journeys['behavioral']!.product?.id, 'lookup');
      expect(journeys['digital']!.product?.id, 'lookup');
      expect(
        journeys['behavioral']!.screens.length,
        journeys['digital']!.screens.length,
      );
    });

    test('BreatheFree is 23 screens of approved artwork', () {
      final journey = journeys['tobacco']!;
      expect(journey.isGenerated, isFalse);
      expect(journey.screens, hasLength(23));

      // Not "awaiting copy". The bundle ships no content file for BreatheFree
      // because its design is 1290 × 2796 images that already went through
      // review — there are no slots to fill. Every one of the 23 renders.
      expect(
        journey.withReadiness(JourneyReadiness.artwork),
        hasLength(23),
      );
      expect(journey.awaitingCopy, isEmpty);
      expect(journey.awaitingArchetype, isEmpty);
    });

    test('each BreatheFree screen maps to its approved image', () {
      // `S05` is the trigger map and `screen-05-trigger-map` is a picture of
      // the trigger map. The two numbering schemes agree, and this is the
      // assertion that keeps them agreeing.
      final journey = journeys['tobacco']!;
      for (final screen in journey.screens) {
        final number = screen.approvedScreen;
        expect(number, isNotNull, reason: screen.id);
        expect(
          'S${number.toString().padLeft(2, '0')}',
          screen.id,
          reason: '${screen.id} maps to artwork $number',
        );
        expect(number, inInclusiveRange(1, 28));
      }
    });

    test('no other program claims approved artwork', () {
      // The 28 images are BreatheFree's. A generated journey borrowing them
      // would be putting a cessation screenshot inside a kidney program.
      for (final journey in journeys.values) {
        if (journey.area.id == 'tobacco') continue;
        expect(
          journey.screens.where((screen) => screen.approvedScreen != null),
          isEmpty,
          reason: journey.area.id,
        );
      }
    });
  });

  group('the eight planned areas generate a journey from the catalogue', () {
    const expected = <String, int>{
      'metabolic': 19,
      'cancer': 14,
      'cardiovascular': 20,
      'nutrition': 24,
      'respiratory': 20,
      'kidney_liver': 14,
      'preventive': 14,
      'aging': 20,
    };

    test('each is the size its catalogue entry implies', () {
      for (final entry in expected.entries) {
        final journey = journeys[entry.key]!;
        expect(journey.isGenerated, isTrue, reason: entry.key);
        expect(journey.screens, hasLength(entry.value), reason: entry.key);
      }
    });

    test('each carries the six shell screens', () {
      for (final id in expected.keys) {
        final shell =
            journeys[id]!.screens.where((screen) => screen.isShell).toList();
        expect(shell, hasLength(6), reason: id);
        for (final screen in shell) {
          expect(screen.archetype, isNotNull, reason: '$id/${screen.id}');
        }
      }
    });

    test('shared archetypes resolve; only the specific ones are unbuilt', () {
      for (final id in expected.keys) {
        final journey = journeys[id]!;
        for (final screen in journey.screens) {
          if (screen.origin == JourneyOrigin.areaSpecific) continue;
          expect(
            screen.archetype,
            isNotNull,
            reason: '$id declares ${screen.archetypeId}, which does not exist',
          );
        }
      }
    });

    test('a generated screen states why the area asked for it', () {
      // `screens.specific` carries the reason, and that reason is the test the
      // bundle uses to stop the shared library fragmenting into eleven
      // bespoke products. It must survive into the UI.
      final cardiovascular = journeys['cardiovascular']!;
      final specific = cardiovascular.screens
          .where((screen) => screen.origin == JourneyOrigin.areaSpecific);
      expect(specific, hasLength(2));
      for (final screen in specific) {
        expect(screen.rationale, isNotNull);
        expect(screen.rationale, isNotEmpty);
      }
    });
  });

  test('the whole app is 236 journey screens across eleven areas', () {
    // Not a target, just the current size, stated so that a change to it is
    // visible in a diff rather than discovered later.
    final total = journeys.values.fold<int>(
      0,
      (sum, journey) => sum + journey.screens.length,
    );
    expect(total, 34 + 34 + 23 + 19 + 14 + 20 + 24 + 20 + 14 + 14 + 20);
    expect(total, 236);
  });
}
