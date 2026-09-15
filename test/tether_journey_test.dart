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
    // and shaped to each area. It used to be carried by `areas.json` alone —
    // nine areas had no product file and got a journey derived from their
    // catalogue entry. All eleven now have a product, so every journey is
    // authored, and the claim is met the stronger way rather than dropped.
    expect(journeys, hasLength(11));
    for (final journey in journeys.values) {
      expect(journey.screens, isNotEmpty, reason: journey.area.id);
      expect(journey.entry, isNotNull, reason: journey.area.id);
    }
  });

  test('no programme is entirely empty', () {
    // Eight products were written by four different authors, and the way that
    // goes wrong quietly is a product file that pins a screen list nobody ever
    // wrote content for: eleven programmes in the directory, and one of them
    // is a run of slot stubs a person can page through learning nothing.
    //
    // "Drawable" is the line that matters, not "has screens". A journey made
    // entirely of `awaitingCopy` screens has screens and is still empty in the
    // only sense a reader cares about.
    for (final journey in journeys.values) {
      final drawable =
          journey.screens.where((screen) => screen.isDrawable).toList();
      expect(
        drawable,
        isNotEmpty,
        reason: '${journey.area.id} has ${journey.screens.length} screens and '
            'not one of them can be shown to a person',
      );
    }
  });

  test('no programme has a dead end', () {
    // `Journey.deadEnds` is the bundle's first acceptance test — "no dead
    // ends" — asked of every programme rather than only of LookUp. It passes
    // for all eleven today, and it is asserted here because the eight products
    // written here are the kind of thing that breaks it: a `to:` pointing at a
    // screen id the author meant to add and did not is invisible in review and
    // is a button that goes nowhere in the app.
    for (final journey in journeys.values) {
      expect(
        journey.deadEnds,
        isEmpty,
        reason: '${journey.area.id} points at screens it does not contain: '
            '${journey.deadEnds.toList()..sort()}',
      );
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

  // The two products the bundle itself ships. Ten programmes are authored now,
  // but these two are the ones whose screen lists came from outside this
  // repository, and they are the reference the other eight were written
  // against.
  group('the two products the bundle ships', () {
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

  group('the eight programmes written here', () {
    // These eight areas used to have no product file, and their journeys were
    // derived from `areas.json` — the same screen list, in the shared
    // library's own order, with `isGenerated` true to mark the result as a
    // proposal rather than a decision. Each now has a product in
    // `supplement.product.<areaId>.json`, so the derivation no longer runs for
    // any of them.
    //
    // The sizes below are the product files' screen lists, not the catalogue's
    // implied counts, and seven of the eight happen to match what the
    // catalogue implied. Nutrition does not: it was 24 derived and is 25
    // authored, because OneChange pins a screen the area's shared list did not
    // ask for.
    const expected = <String, int>{
      'metabolic': 19,
      'cancer': 14,
      'cardiovascular': 20,
      'nutrition': 25,
      'respiratory': 20,
      'kidney_liver': 14,
      'preventive': 14,
      'aging': 20,
    };

    test('each is the size its product file pins', () {
      for (final entry in expected.entries) {
        final journey = journeys[entry.key]!;
        // The inversion worth stating out loud. `isGenerated` is what the UI
        // reads to decide whether to present a programme as a proposal, and
        // these eight stopped being proposals.
        expect(journey.isGenerated, isFalse, reason: entry.key);
        expect(journey.product, isNotNull, reason: entry.key);
        expect(journey.screens, hasLength(entry.value), reason: entry.key);
      }
    });

    test('none of the eleven is generated any more', () {
      // Asserted across all eleven rather than only the eight, because the
      // moment one area loses its product the `_fromCatalogue` path is live
      // again and every count in this file is describing a different journey.
      for (final journey in journeys.values) {
        expect(journey.isGenerated, isFalse, reason: journey.area.id);
        expect(
          journey.screens.map((screen) => screen.origin).toSet(),
          {JourneyOrigin.product},
          reason: journey.area.id,
        );
      }
    });

    test('each carries the six shell screens', () {
      // `shell.json` says the shell is built once and is identical in every
      // area. That used to be guaranteed by `JourneyBuilder` appending SH1..SH6
      // to every derived journey whether the area listed them or not; now each
      // of the eight product files has to pin them itself, which is the weaker
      // guarantee and therefore the one worth testing.
      for (final id in expected.keys) {
        final shell =
            journeys[id]!.screens.where((screen) => screen.isShell).toList();
        expect(shell, hasLength(6), reason: id);
        for (final screen in shell) {
          expect(screen.archetype, isNotNull, reason: '$id/${screen.id}');
        }
      }
    });

    test('every archetype these eight name exists', () {
      // This used to have to exempt `screens.specific`, because an area was
      // allowed to name an archetype the shared library had not built and the
      // journey rendered it as unbuilt. There is no exemption now: the four
      // archetypes those areas were missing — `reading_log`, `due_record`,
      // `supporter_view`, `share_preview` — were added to
      // `supplement.archetypes.json` when the products were written, so every
      // screen in all eight has something that can draw it.
      for (final id in expected.keys) {
        final journey = journeys[id]!;
        for (final screen in journey.screens) {
          expect(
            screen.archetype,
            isNotNull,
            reason: '$id pins ${screen.archetypeId}, which does not exist',
          );
        }
        expect(journey.awaitingArchetype, isEmpty, reason: id);
      }
    });

    test('a proposed screen states why the programme asked for it', () {
      // The reason is the test the bundle uses to stop the shared library
      // fragmenting into eleven bespoke products, and it must survive into the
      // UI. It used to travel on `screens.specific` in `areas.json`; for an
      // authored programme it travels on the product's `proposedArchetypes`
      // instead, and `JourneyBuilder` attaches it to every screen drawing one.
      //
      // Cancer is the case here: WorthAsking proposes `due_record` and pins it
      // at S05. Cardiovascular, which used to carry two of these, no longer
      // carries any — SteadyBeat draws only promoted archetypes.
      final cancer = journeys['cancer']!;
      final proposed =
          cancer.screens.where((screen) => screen.isProposed).toList();
      expect(proposed.map((screen) => screen.archetypeId), ['due_record']);
      for (final screen in proposed) {
        expect(screen.rationale, isNotNull, reason: screen.id);
        expect(screen.rationale, isNotEmpty, reason: screen.id);
      }

      // And the rule holds everywhere it is declared, not just where it was
      // checked: if a product lists an archetype in `proposedArchetypes`,
      // every screen drawing it carries that reason.
      for (final journey in journeys.values) {
        final declared = {
          for (final entry in journey.product?.proposedArchetypes ?? const [])
            entry.id,
        };
        for (final screen in journey.screens) {
          if (!declared.contains(screen.archetypeId)) continue;
          expect(
            screen.rationale,
            isNotNull,
            reason: '${journey.area.id}/${screen.id} draws the proposed '
                '${screen.archetypeId} without stating why',
          );
          expect(screen.rationale, isNotEmpty,
              reason: '${journey.area.id}/${screen.id}');
        }
      }
    });

    test('every proposed archetype says why it had to be new', () {
      // A `$new` screen and a `proposedArchetypes` entry are two different
      // flags in a product file, and only the second carries a reason.
      //
      // The bundle's rule for adding an area is that anything not fitting an
      // existing archetype "must name which *other* areas could reuse it —
      // that test is what stops the shared library fragmenting into ten
      // bespoke products". An unreasoned proposal is how the fragmenting
      // starts, because nobody reviewing it later can tell whether the
      // argument was made and lost or never made at all.
      //
      // Two of the eight products written here originally set the first flag
      // without the second: SteadyAir and LongView both pinned `reading_log`
      // as new and neither said why. Both now quote the reuse argument from
      // their own area's catalogue entry — `reading_log` is shared by four
      // areas, which is exactly the test being asked for.
      final unreasoned = <String>[
        for (final journey in journeys.values)
          for (final screen in journey.screens)
            if (screen.isProposed &&
                (screen.rationale == null || screen.rationale!.isEmpty))
              '${journey.area.id}/${screen.id}/${screen.archetypeId}',
      ]..sort();

      expect(
        unreasoned,
        isEmpty,
        reason: 'a screen proposes a new archetype and never says why: '
            '${unreasoned.join(', ')}',
      );

      // And the rule is not vacuous — there really are proposals to check.
      final proposed = [
        for (final journey in journeys.values)
          for (final screen in journey.screens)
            if (screen.isProposed) '${journey.area.id}/${screen.archetypeId}',
      ];
      expect(proposed, isNotEmpty);
    });
  });

  test('the whole app is 237 journey screens across eleven areas', () {
    // Not a target, just the current size, stated so that a change to it is
    // visible in a diff rather than discovered later. It was 236 while eight
    // of the eleven were derived from the catalogue; OneChange pins one screen
    // more than nutrition's catalogue entry implied, and that is the whole of
    // the difference.
    final total = journeys.values.fold<int>(
      0,
      (sum, journey) => sum + journey.screens.length,
    );
    expect(total, 23 + 19 + 14 + 20 + 25 + 20 + 14 + 34 + 14 + 20 + 34);
    expect(total, 237);
  });
}
