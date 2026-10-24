import 'package:flutter_test/flutter_test.dart';
import 'package:tether_health/tether/data/bundle_loader.dart';
import 'package:tether_health/tether/data/design_bundle.dart';
import 'package:tether_health/tether/state/tether_session.dart';

import 'tether_bundle_test.dart' show CatalogueOnlyAssetBundle, DiskAssetBundle;

/// The safeguards, turned into something that fails the build.
///
/// `safeguards.json` says it plainly: these are "the rules most likely to be
/// quietly violated by someone shipping fast, so they are machine-checkable
/// rather than living in a document nobody rereads". A safeguard that is only
/// written down is a safeguard that survives exactly until the first deadline.
void main() {
  late DesignBundle bundle;

  setUpAll(() async {
    bundle = await BundleLoader.load(bundle: DiskAssetBundle());
  });

  TetherSession session() => TetherSession(bundle: bundle);

  group('crisis routing comes first', () {
    test('both crisis-bearing archetypes pin their card first', () {
      // The slot spec is `required:first`, not `required`. The distinction is
      // the entire safeguard: a crisis card that can be sorted, collapsed or
      // pushed below a coach row is not a crisis route.
      expect(bundle.archetypes['support_hub']!.slots['crisisCard'],
          'required:first');
      expect(bundle.archetypes['crisis_route']!.slots['emergencyCard'],
          'required:first');
    });

    test('both declare the safeguard capability', () {
      expect(
        bundle.archetypes['support_hub']!.requires,
        contains('crisis_card_pinned_first'),
      );
      expect(
        bundle.archetypes['crisis_route']!.requires,
        contains('crisis_card_pinned_first'),
      );
      expect(
        bundle.shell.screens
            .firstWhere((screen) => screen.id == 'SH6')
            .requires,
        contains('crisis_card_pinned_first'),
      );
    });

    test('there is exactly one crisis route in the shell', () {
      // `one_crisis_route`: per-program crisis copy will be wrong in at least
      // one program. One route, reviewed once, reachable everywhere.
      final crisisScreens = bundle.shell.screens.where(
        (screen) => screen.requires.contains('crisis_card_pinned_first'),
      );
      expect(crisisScreens, hasLength(1));
      expect(bundle.shell.rule('one_crisis_route'), isNotNull);
    });
  });

  group('a slip is an event, not a reset', () {
    test('the archetypes that can see a lapse declare the safeguard', () {
      expect(
          bundle.archetypes['lapse']!.requires, contains('slip_never_resets'));
      expect(bundle.archetypes['progress']!.requires,
          contains('slip_never_resets'));
    });

    test('the safeguard forbids zeroing a streak', () {
      expect(
        bundle.safeguards['slip_never_resets']!.forbids,
        contains('streak_reset_on_lapse'),
      );
    });

    test('recording a lapse changes nothing except the history', () {
      final state = session();
      state.join('digital');
      state.setSlider('digital', 'S13', 2, 60);
      state.toggleChip('digital', 'S13', 0, 3);
      final joinedOn = state.enrolment('digital').joinedOn;

      state.recordLapse(
        LapseEvent(
          areaId: 'digital',
          at: DateTime(2026, 9, 12),
          severity: 'A long evening on it',
          context: const ['In bed'],
        ),
      );

      // The lapse is in history.
      expect(state.lapsesFor('digital'), hasLength(1));
      // And nothing else moved: the program is still active, joined on the
      // same day, with the same answers behind it.
      expect(state.enrolment('digital').status, EnrolmentStatus.active);
      expect(state.enrolment('digital').joinedOn, joinedOn);
      expect(state.answersFor('digital', 'S13').slider[2], 60);
      expect(state.answersFor('digital', 'S13').chips[0], contains(3));
    });
  });

  group('at most two programs at once', () {
    test('the ceiling comes from the shell rule', () {
      expect(bundle.shell.maxActivePrograms, 2);
      expect(bundle.shell.rule('two_active_max')!.why, contains('adherence'));
    });

    test('a third join is refused rather than silently allowed', () {
      final state = session();
      expect(state.join('tobacco').joined, isTrue);
      expect(state.join('digital').joined, isTrue);

      final third = state.join('behavioral');
      expect(third.joined, isFalse);
      expect(third.refusal, JoinRefusal.atActiveCeiling);
      // And it names what would have to give way, so the screen can offer the
      // trade instead of performing it.
      expect(third.wouldPause, isNotNull);
      expect(state.activePrograms, hasLength(2));
    });

    test('naming a program to pause turns the refusal into a choice', () {
      final state = session();
      state.join('tobacco');
      state.join('digital');

      expect(state.join('behavioral', pausing: 'tobacco').joined, isTrue);
      expect(state.enrolment('tobacco').status, EnrolmentStatus.paused);
      expect(state.activePrograms, hasLength(2));
    });

    test('every one of the eleven can now be joined', () {
      // This test used to read "an area with no implementation cannot be
      // joined at all", and `cancer` was the example: nine of the eleven were
      // a plan, and offering a join would have been the app claiming something
      // that does not exist.
      //
      // Eight products were written and every area now has one, so the rule
      // has no subject left in the shipped data. The change is recorded here
      // as the new fact rather than the old test being quietly deleted — and
      // it is a fact worth pinning, because `not_every_area_ships` cuts both
      // ways: an area that has a programme and refuses to start it is the same
      // kind of lie as one that has none and offers to.
      for (final area in bundle.areas) {
        final state = session();
        final outcome = state.join(area.id);
        expect(
          outcome.joined,
          isTrue,
          reason: '${area.id} has ${area.productId} behind it and still '
              'refused the join: ${outcome.refusal}',
        );
        expect(state.activePrograms, hasLength(1), reason: area.id);
      }
    });

    test('an area with no implementation still cannot be joined', () async {
      // The refusal itself is live code — `JoinRefusal.areaNotImplemented` is
      // the first thing `canJoin` tests and the thing SH3 reads to decide
      // whether to draw a Join button at all. It is the rule that runs the next
      // time an area is added to the catalogue ahead of its product.
      //
      // So it is tested against the catalogue as the bundle actually ships it,
      // where eight areas still carry `productId: null`. See
      // [CatalogueOnlyAssetBundle]: this is the shipped `areas.json`, not a
      // mock of one.
      final catalogue = await BundleLoader.load(
        bundle: CatalogueOnlyAssetBundle(),
      );
      final planned =
          catalogue.areas.where((area) => area.productId == null).toList();
      expect(planned, hasLength(8));

      for (final area in planned) {
        final state = TetherSession(bundle: catalogue);
        final outcome = state.join(area.id);
        expect(outcome.joined, isFalse, reason: area.id);
        expect(outcome.refusal, JoinRefusal.areaNotImplemented,
            reason: area.id);
        expect(state.activePrograms, isEmpty, reason: area.id);
      }

      // And naming a program to pause does not get round it. The ceiling is a
      // trade a person can make; a missing implementation is not.
      final state = TetherSession(bundle: catalogue);
      state.join('tobacco');
      expect(
        state.join('cancer', pausing: 'tobacco').refusal,
        JoinRefusal.areaNotImplemented,
      );
      expect(state.enrolment('tobacco').status, EnrolmentStatus.active);
    });
  });

  group('nothing is shared by default', () {
    test('a new enrolment shares nothing', () {
      final state = session();
      state.join('digital');
      final sharing = state.enrolment('digital').sharing;
      expect(sharing.totalsAndAdherence, isFalse);
      expect(sharing.notes, isFalse);
      expect(sharing.sharesAnything, isFalse);
    });

    test('sharing is per program, never pooled', () {
      // 42 CFR Part 2: substance-use data stays segregated regardless. Turning
      // sharing on for one program must not touch another.
      final state = session();
      state.join('tobacco');
      state.join('digital');
      state.setSharing(
        'digital',
        const SharingSetting(totalsAndAdherence: true, recipient: 'Maya'),
      );

      expect(state.enrolment('digital').sharing.totalsAndAdherence, isTrue);
      expect(state.enrolment('tobacco').sharing.sharesAnything, isFalse);
    });

    test('the shell states why they are separate', () {
      expect(bundle.shell.rule('per_program_sharing')!.why,
          contains('42 CFR Part 2'));
    });

    test('two programs on one product keep separate answers', () {
      // `per_program_sharing`, quoted: "A cessation coach has no business
      // seeing behavioural health data. Under 42 CFR Part 2, substance-use
      // data must be segregated regardless."
      //
      // Sharing being per program is not enough on its own. `behavioral` and
      // `digital` both declare `productId: "lookup"` in `areas.json`, so
      // `JourneyBuilder` hands them the same screen list — the same ids, not
      // merely the same shapes — and `two_active_max` permits both to be
      // active at once. While answers were keyed by screen id alone, the two
      // programmes were writing into one record: a rating given to the
      // behavioural-health programme was readable from the screen-time one
      // without anybody sharing anything. That is the merge this checks is
      // gone.
      final state = session();
      expect(state.join('behavioral').joined, isTrue);
      expect(state.join('digital').joined, isTrue);

      // Asserted rather than assumed. If the catalogue ever stops giving these
      // two the same ids, the rest of this test stops proving anything, and it
      // would go on passing while it did so.
      final behaviouralIds =
          state.journey('behavioral')!.screens.map((s) => s.id).toSet();
      final digitalIds =
          state.journey('digital')!.screens.map((s) => s.id).toSet();
      expect(behaviouralIds, digitalIds);
      expect(behaviouralIds, containsAll(['S13', 'S09']));

      state.setSlider('behavioral', 'S13', 2, 90);
      state.toggleChip('behavioral', 'S13', 0, 3);
      state.setText('behavioral', 'S09', 0, 'Only for this program.');

      // The other program cannot see any of it.
      expect(state.answersFor('digital', 'S13').slider[2], isNull);
      expect(state.answersFor('digital', 'S13').chips[0], isNull);
      expect(state.answersFor('digital', 'S09').text[0], isNull);

      // And the program it was given in still has all of it.
      expect(state.answersFor('behavioral', 'S13').slider[2], 90);
      expect(state.answersFor('behavioral', 'S13').chips[0], contains(3));
      expect(
        state.answersFor('behavioral', 'S09').text[0],
        'Only for this program.',
      );

      // The export agrees: one program holds it, the other holds nothing, and
      // there is no third place holding it for both.
      final programs = (state.exportRecord()['programs']! as List)
          .cast<Map<String, Object?>>();
      final answersByArea = {
        for (final program in programs)
          program['area']! as String: program['answers']! as Map,
      };
      expect(answersByArea['behavioral']!.keys, containsAll(['S13', 'S09']));
      expect(answersByArea['digital'], isEmpty);
    });
  });

  group('export and deletion', () {
    test('the archetypes that hold data declare the safeguard', () {
      expect(bundle.archetypes['consent']!.requires,
          contains('export_and_delete'));
      expect(bundle.archetypes['settings']!.requires,
          contains('export_and_delete'));
    });

    test('the safeguard demands a real delete, not a hide', () {
      expect(
        bundle.safeguards['export_and_delete']!.requires,
        containsAll(['export_action', 'hard_delete_action']),
      );
    });

    test('an export carries every joined program and its answers', () {
      final state = session();
      state.join('digital');
      state.setText('digital', 'S09', 0, 'I want my evenings back.');
      state.chooseOption('digital', 'S07', 0, 1);

      final record = state.exportRecord();
      final programs = record['programs']! as List;
      expect(programs, hasLength(1));
      expect((programs.first as Map)['area'], 'digital');

      // Answers travel inside the program that recorded them, not in a flat
      // map beside the programs. A reader of this export cannot come away
      // thinking there is one shared pool of answers under both programmes,
      // because the shape does not offer that reading.
      final answers = (programs.first as Map)['answers']! as Map;
      expect(answers.keys, containsAll(['S09', 'S07']));
    });

    test('deleting everything leaves nothing behind', () {
      final state = session();
      state.join('digital');
      state.setSlider('digital', 'S17', 0, 70);
      state.recordLapse(
        LapseEvent(
          areaId: 'digital',
          at: DateTime(2026, 9, 12),
          severity: 'A bit over',
          context: const [],
        ),
      );

      state.deleteEverything();

      expect(state.activePrograms, isEmpty);
      expect(state.enrolment('digital').isJoined, isFalse);
      expect(state.lapses, isEmpty);
      expect((state.exportRecord()['programs']! as List), isEmpty);
    });
  });

  group('the shell rules hold', () {
    test('the home screen never lists the eleven areas', () {
      // `no_area_directory_on_home`: a directory leaks what a person is
      // dealing with to anyone who picks up the phone. The home archetype's
      // slots are checked rather than the rendered widget, because this is a
      // property of the design, and a slot list that grew an area row would
      // be the first sign of it going wrong.
      final home = bundle.archetypes['home']!;
      expect(home.slots.keys, isNot(contains('areaRows')));
      expect(
        home.slots.keys.any((slot) => slot.toLowerCase().contains('area')),
        isFalse,
      );

      // The directory lives on SH2, reached on request.
      expect(
        bundle.archetypes['area_directory']!.slots['areaRows'],
        'required:11',
      );
    });

    test('a program can be hidden from the home screen', () {
      final state = session();
      state.join('tobacco');
      expect(state.visiblePrograms, hasLength(1));

      state.setHidden('tobacco', hidden: true);
      expect(state.visiblePrograms, isEmpty);
      // Hidden is not paused. It is still running.
      expect(state.activePrograms, hasLength(1));
      expect(bundle.shell.rule('discreet_program')!.why, contains('Stigma'));
    });

    test('areas carrying clinical thresholds are identifiable', () {
      // `threshold_areas_separable`: regulatory classification follows the
      // riskiest feature in the binary, so these have to be removable on
      // their own. Nothing can be flagged that cannot first be found.
      final flagged = bundle.areas
          .where((area) => area.hasClinicalThresholds)
          .map((area) => area.id)
          .toSet();
      expect(
        flagged,
        {'metabolic', 'cardiovascular', 'respiratory', 'kidney_liver'},
      );
    });
  });

  group('self-report is never presented as measurement', () {
    test('the archetypes that collect a rating say so', () {
      for (final id in ['baseline', 'checkin', 'rescue_recheck']) {
        expect(
          bundle.archetypes[id]!.requires,
          contains('self_report_disclaimer'),
          reason: '$id collects a rating without disclaiming it',
        );
      }
    });

    test('the rescue runs offline and sends nothing', () {
      // The rescue flow was designed for somebody in bed at 11pm. Requiring a
      // network round trip there would break it exactly when it is needed.
      final rescue = bundle.archetypes['rescue_active']!;
      expect(
        rescue.requires,
        containsAll(
            ['offline_capable', 'reduced_motion_fallback', 'no_data_sent']),
      );
      expect(
        bundle.archetypes['rescue_start']!.requires,
        contains('offline_capable'),
      );
    });

    test('distress never terminates at a non-clinical coach', () {
      expect(bundle.archetypes['checkin']!.requires,
          contains('distress_escalation'));
      expect(
        bundle.safeguards['distress_escalation']!.requires,
        contains('escalation_policy_ref'),
      );
    });
  });

  test('sensitive notifications ship switched off', () {
    final safeguard = bundle.safeguards['sensitive_notifications_off']!;
    expect(safeguard.defaultOff, isTrue);
    expect(safeguard.requires, contains('generic_notification_copy'));
    expect(bundle.archetypes['settings']!.requires,
        contains('sensitive_notifications_off'));
  });
}
