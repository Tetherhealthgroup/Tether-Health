import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_health/tether/data/bundle_loader.dart';
import 'package:tether_health/tether/data/design_bundle.dart';
import 'package:tether_health/tether/journey/journey.dart';

/// Reads the design assets off disk instead of out of a built asset bundle.
///
/// The parsing these tests exercise has nothing to do with how the bytes
/// arrived, and going through the filesystem means the same tests also catch
/// a file that was moved or renamed without `pubspec.yaml` being updated.
class DiskAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.view(
        bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);
  }
}

/// The same assets with `supplement.product.*.json` withheld.
///
/// Every one of the eleven areas now has a product bound to it, which means
/// two rules the app still enforces have no subject left in the shipped data:
/// [JourneyBuilder]'s catalogue path, and the refusal to join an area with no
/// implementation. Deleting their tests would retire live code from the suite
/// while leaving it in the binary.
///
/// So the rules are tested against the catalogue as the bundle actually ships
/// it. This is not a mock: `areas.json` is the verbatim shipped file and eight
/// of its areas carry `productId: null`. Withholding this repository's eight
/// product files reproduces the bundle exactly, and it also exercises the
/// contract [BundleLoader] documents for the supplement — that a missing
/// supplement file degrades rather than throws.
class CatalogueOnlyAssetBundle extends DiskAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.contains('supplement.product.')) {
      throw StateError('withheld by CatalogueOnlyAssetBundle: $key');
    }
    return super.load(key);
  }
}

void main() {
  late DesignBundle bundle;

  setUpAll(() async {
    bundle = await BundleLoader.load(bundle: DiskAssetBundle());
  });

  group('the bundle parses', () {
    test('every layer is present and the right size', () {
      // These counts are the bundle as shipped. They are asserted rather than
      // derived so that adding an area, promoting an archetype or retiring a
      // safeguard is a decision somebody takes deliberately and updates here,
      // not something that slips in with a JSON edit.
      expect(bundle.areas, hasLength(11));
      // 29 from the shipped library, plus the six proposed in this repository:
      // `age_gate` and `environment` for LookUp, and `reading_log`,
      // `due_record`, `supporter_view` and `share_preview` for the eight
      // programmes written here. See the supplement group below.
      expect(bundle.archetypes, hasLength(35));
      expect(bundle.safeguards, hasLength(20));
      expect(bundle.shell.screens, hasLength(6));
      expect(bundle.shell.rules, hasLength(7));

      // Two products ship in the bundle; eight more were written here, one per
      // area the catalogue left as a plan. Asserted as an exact count for the
      // same reason as the rest of this test: a ninth programme appearing is a
      // decision, and it should have to be written down twice.
      expect(bundle.products.keys, containsAll(['breathefree', 'lookup']));
      expect(bundle.products, hasLength(10));

      // Nine content packs for ten products. BreatheFree is the one without,
      // and that is a property of the product rather than a gap — see the
      // artwork test below.
      expect(bundle.content, hasLength(9));
    });

    test('the areas are the eleven the website publishes', () {
      expect(
        bundle.areas.map((area) => area.id),
        [
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
        ],
      );

      for (final area in bundle.areas) {
        expect(
          area.url,
          startsWith('https://www.tetherhealthgroup.com/programs/'),
          reason: '${area.id} has no public page',
        );
        expect(area.serviceLines, isNotEmpty, reason: area.id);
      }

      // Forty-five service lines across the eleven areas.
      //
      // The bundle's README says forty-one and its "current state" line says
      // ten areas and twenty-three archetypes. The data says forty-five,
      // eleven and twenty-nine. The data wins — the README was written against
      // an earlier revision and was not updated — and this assertion is where
      // that discrepancy is recorded rather than rediscovered.
      final lines = bundle.areas.fold<int>(
        0,
        (total, area) => total + area.serviceLines.length,
      );
      expect(lines, 45);
    });

    test('every area now has an implementation', () {
      // Three of these bindings come from `areas.json` itself; the other eight
      // come from `supplement.product.<areaId>.json`, which is how this
      // repository turns a planned area into a programme without editing the
      // verbatim copy of the shipped catalogue.
      final implemented = {
        for (final area in bundle.areas)
          if (area.productId != null) area.id: area.productId,
      };
      expect(implemented, {
        'tobacco': 'breathefree',
        'metabolic': 'glucosewise',
        'cancer': 'worthasking',
        'cardiovascular': 'steadybeat',
        'nutrition': 'onechange',
        'respiratory': 'steadyair',
        'kidney_liver': 'longview',
        'behavioral': 'lookup',
        'preventive': 'groundwork',
        'aging': 'steady',
        'digital': 'lookup',
      });

      // Status and implementation are tracked separately, and they still
      // disagree. `BundleLoader` moves an area off `planned` when it binds a
      // product to it, so the eight written here are `in_development` or
      // `design` — but `behavioral` and `digital` are `planned` in
      // `areas.json` and point at LookUp, which the bundle binds rather than
      // the supplement, so nothing moved their label. Two areas therefore read
      // "planned" while offering a programme somebody can join.
      //
      // SH2 has to render that distinction rather than flatten it: a person
      // reading "planned" next to an area that has a joinable program would
      // be right to stop trusting the labels. The product carries its own
      // status, so an area being planned does not mean no design work exists
      // for it.
      final byStatus = <AreaStatus, int>{};
      for (final area in bundle.areas) {
        byStatus[area.status] = (byStatus[area.status] ?? 0) + 1;
      }
      expect(byStatus, {
        AreaStatus.inDevelopment: 7,
        AreaStatus.design: 2,
        AreaStatus.planned: 2,
      });
      expect(
        bundle.areas
            .where((area) => area.status == AreaStatus.planned)
            .map((area) => area.id),
        ['behavioral', 'digital'],
      );
      expect(bundle.products['lookup']!.status, 'design');
      expect(bundle.products['breathefree']!.status, 'in_development');
    });

    test('LookUp has 34 screens and all 34 are written', () {
      final lookup = bundle.products['lookup']!;
      expect(lookup.screens, hasLength(34));

      final content = bundle.contentFor('lookup', 'en')!;
      expect(content.screens, hasLength(34));
      expect(content.start, 'S01');

      // 24 shipped in the bundle; 10 were written here to close the gap.
      expect(content.unreviewed, hasLength(10));
    });

    test('BreatheFree has 23 screens and no content file', () {
      expect(bundle.products['breathefree']!.screens, hasLength(23));

      // Its 28 approved screens are artwork, not authored slots, so there is
      // nothing to render from JSON. That is a fact about the product, not a
      // gap in the loader.
      expect(bundle.contentFor('breathefree', 'en'), isNull);
    });

    test('each product renames the shared concepts in its own words', () {
      expect(bundle.products['lookup']!.word('urge'), 'pull');
      expect(bundle.products['breathefree']!.word('urge'), 'craving');
      // A concept the product has not renamed comes back unchanged.
      expect(bundle.products['lookup']!.word('sleep'), 'sleep');
    });
  });

  group('cross-references resolve', () {
    test('every safeguard an area names exists', () {
      expect(bundle.unresolvedSafeguardIds, isEmpty);
    });

    test('every archetype requirement is a safeguard or a capability', () {
      // Fourteen distinct tokens appear across the archetypes. Six are
      // safeguard ids; three name a capability some safeguard requires; five
      // are archetype-level capabilities with no safeguard behind them. All
      // three kinds are binding, and the split is asserted so that a token
      // silently changing category is caught.
      // Scoped to the shipped library. The two archetypes proposed here are
      // held to the same rule by the supplement group below, but they must not
      // be able to change what the bundle is asserted to contain.
      final requirements = {
        for (final archetype in bundle.archetypes.values)
          if (archetype.provenance == ContentProvenance.bundle)
            ...archetype.requires,
      };
      expect(requirements, hasLength(14));

      final asSafeguards =
          requirements.where(bundle.safeguards.containsKey).toSet();
      expect(asSafeguards, hasLength(6));

      final asNamedCapabilities =
          requirements.difference(asSafeguards).intersection(
                bundle.capabilities,
              );
      expect(
        asNamedCapabilities,
        {'crisis_card_pinned_first', 'self_report_disclaimer', 'share_preview'},
      );

      final standalone =
          requirements.difference(asSafeguards).difference(bundle.capabilities);
      expect(
        standalone,
        {
          'offline_capable',
          'no_data_sent',
          'reduced_motion_fallback',
          'product_disclaimer',
          'review_date',
        },
      );
    });

    test('three archetypes are still unbuilt', () {
      // Nine were unbuilt in the shipped bundle. Six are now defined in the
      // supplement — `age_gate` and `environment` for LookUp, and
      // `reading_log`, `due_record`, `supporter_view` and `share_preview`
      // because the eight programmes written here draw them — which leaves
      // three.
      //
      // All three are named by an area whose product does not use them:
      // `medication_center` by tobacco, which BreatheFree's 23 approved
      // screens do not include; `instrument` by behavioral, whose product is
      // LookUp. Building either would mean designing a screen no product asks
      // for.
      //
      // `intercept` stays on this list on purpose, and for the opposite
      // reason. Its screen, `S22`, has finished copy and renders; the
      // archetype behind it was never promoted.
      expect(bundle.unpromotedArchetypeIds, {
        'instrument',
        'intercept',
        'medication_center',
      });

      // No screen anywhere is left unbuilt by that. The three ids above are
      // declared by an area or pinned by a product screen that has copy, so
      // none of them reaches a renderer with nothing behind it — which is why
      // `JourneyReadiness.awaitingArchetype` no longer occurs in the app. That
      // arm is still live code and is tested directly in
      // `test/tether_app_test.dart`.
      for (final journey in JourneyBuilder.all(bundle)) {
        expect(
          journey.awaitingArchetype,
          isEmpty,
          reason: '${journey.area.id} still renders an unbuilt archetype',
        );
      }
    });

    test('every shell screen has an archetype that draws it', () async {
      // `shell.json` numbers its screens SH1..SH6; `archetypes.json` names the
      // same six `programs_home`..`crisis_route`. The journey builder is the
      // only place those two vocabularies meet, so if the mapping rots this is
      // where it shows: a journey would carry shell screens with no archetype
      // behind them and they would render as unbuilt.
      //
      // Ten of the eleven programmes pin SH1..SH6 in their product file, so
      // the mapping is checked there first — that is the path the app runs.
      var checked = 0;
      for (final journey in JourneyBuilder.all(bundle)) {
        for (final screen in journey.screens.where((s) => s.isShell)) {
          expect(
            screen.archetype,
            isNotNull,
            reason: '${journey.area.id}/${screen.id}: '
                '${screen.archetypeId} has no archetype in the library',
          );
          checked++;
        }
      }
      // Six each for the ten programmes that carry the shell. BreatheFree is
      // the exception: its product file is 23 approved artwork screens and
      // pins none of the shell's six.
      expect(checked, 60);

      // The other half of the mapping is `JourneyBuilder._shellArchetypeId`,
      // reached only when an area has no product and its journey is derived
      // from `areas.json`. Every area now has a product, so that path has no
      // subject left in the shipped data — it is tested against the catalogue
      // as the bundle ships it. See [CatalogueOnlyAssetBundle].
      final catalogue = await BundleLoader.load(
        bundle: CatalogueOnlyAssetBundle(),
      );
      final planned =
          catalogue.areas.where((area) => area.productId == null).toList();
      expect(
        planned,
        hasLength(8),
        reason: 'the shipped catalogue no longer leaves any area unbuilt',
      );

      for (final area in planned) {
        final generated = JourneyBuilder.forArea(catalogue, area);
        expect(generated.isGenerated, isTrue, reason: area.id);
        final shellScreens =
            generated.screens.where((screen) => screen.isShell).toList();

        expect(shellScreens, hasLength(6), reason: area.id);
        for (final screen in shellScreens) {
          expect(
            screen.archetype,
            isNotNull,
            reason: '${area.id}/${screen.archetypeId} '
                'has no archetype in the library',
          );
        }
      }
    });

    test('the two-at-once ceiling is read from the shell, not hard-coded', () {
      expect(bundle.shell.maxActivePrograms, 2);
      expect(bundle.shell.rule('two_active_max'), isNotNull);
      expect(bundle.shell.rule('one_crisis_route'), isNotNull);
    });
  });

  /// The archetypes this repository proposes rather than the bundle shipping.
  ///
  /// Named once so the two tests below cannot drift apart: one asserts the set
  /// is exactly this, the other asserts nothing outside it carries supplement
  /// provenance, and they only mean something together.
  const proposedHere = <String>{
    'age_gate',
    'due_record',
    'environment',
    'reading_log',
    'share_preview',
    'supporter_view',
  };

  group('the supplement fills gaps and never overrides', () {
    test('every screen the bundle wrote is still the bundle\'s', () {
      // The supplement may only reach screens the bundle left empty. If a
      // future bundle ships copy for one of the ten written here, the bundle's
      // wins on the next load with nobody having to remember to delete the
      // local one — and this is the assertion that proves the precedence runs
      // in that direction rather than the other.
      const shipped = <String>{
        'S01',
        'S03',
        'S05',
        'S07',
        'S08',
        'S09',
        'S11',
        'S12',
        'S13',
        'S14',
        'S17',
        'S18',
        'S19',
        'S20',
        'S21',
        'S22',
        'S23',
        'S27',
        'SH1',
        'SH2',
        'SH3',
        'SH4',
        'SH5',
        'SH6',
      };

      final content = bundle.contentFor('lookup', 'en')!;
      for (final id in shipped) {
        expect(
          content.screen(id)!.provenance,
          ContentProvenance.bundle,
          reason: '$id was overridden by the supplement',
        );
      }
    });

    test('the ten written here are the ten the bundle left empty', () {
      final content = bundle.contentFor('lookup', 'en')!;
      expect(
        content.unreviewed.map((screen) => screen.id).toSet(),
        {'S02', 'S04', 'S06', 'S10', 'S15', 'S16', 'S24', 'S25', 'S26', 'S28'},
      );
    });

    test('the six proposed archetypes are marked as such', () {
      final proposed = {
        for (final archetype in bundle.archetypes.values)
          if (archetype.provenance == ContentProvenance.supplement)
            archetype.id,
      };
      expect(proposed, proposedHere);

      // Every one must state which other areas could reuse it. That reuse test
      // is what the bundle uses to stop the shared library fragmenting into
      // eleven bespoke products, and a proposal that skips it is how the
      // fragmenting starts. It is the binding rule for the four added for the
      // eight programmes written here: `reading_log` is drawn by four areas
      // and `due_record` by two, which is the argument for building them at
      // all rather than giving each area its own.
      for (final id in proposed) {
        expect(bundle.archetypes[id]!.notes, isNotNull, reason: id);
        expect(bundle.archetypes[id]!.notes, isNotEmpty, reason: id);
        expect(bundle.archetypes[id]!.slots, isNotEmpty, reason: id);
      }
    });

    test('no archetype in the shared library was shadowed', () {
      for (final archetype in bundle.archetypes.values) {
        if (archetype.provenance != ContentProvenance.supplement) continue;
        expect(
          proposedHere.contains(archetype.id),
          isTrue,
          reason: '${archetype.id} is not one of the six proposed here',
        );
      }

      // Counted from the other side as well. Six proposals landing on 35
      // archetypes only proves nothing was shadowed if the shipped library is
      // still all 29 of the entries `archetypes.json` holds — an override
      // would keep the total at 35 while quietly replacing one of them.
      final shipped = {
        for (final archetype in bundle.archetypes.values)
          if (archetype.provenance == ContentProvenance.bundle) archetype.id,
      };
      final onDisk = {
        for (final json in (jsonDecode(
                File('assets/design/archetypes.json').readAsStringSync())
            as Map<String, Object?>)['archetypes']! as List<Object?>)
          (json! as Map<String, Object?>)['id']! as String,
      };
      expect(onDisk, hasLength(29));
      expect(shipped, onDisk);
    });
  });

  group('the assets have not drifted from the source bundle', () {
    // Only two of the six design files have a second copy in the repo to
    // compare against; the rest came out of files/tether-design.zip, which
    // cannot be opened without adding an archive package. So this checks what
    // it can and the report says so, rather than implying full coverage.
    for (final name in ['areas.json', 'shell.json']) {
      test(name, () {
        final shipped = File('assets/design/$name');
        final source = File('files/$name');
        if (!source.existsSync()) {
          markTestSkipped('files/$name is not in this checkout');
          return;
        }
        expect(
          jsonDecode(shipped.readAsStringSync()),
          jsonDecode(source.readAsStringSync()),
          reason: 'assets/design/$name no longer matches files/$name',
        );
      });
    }
  });
}
