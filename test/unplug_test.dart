import 'dart:io';

import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/models/prototype_catalog.dart';
import 'package:breathefree_patient/models/screen_spec.dart';
import 'package:breathefree_patient/unplug/models/delivery_track.dart';
import 'package:breathefree_patient/unplug/models/intercept_tokens.dart';
import 'package:breathefree_patient/unplug/models/platform_ceiling.dart';
import 'package:breathefree_patient/unplug/models/program_template.dart';
import 'package:breathefree_patient/unplug/models/unplug_module_state.dart';
import 'package:breathefree_patient/unplug/models/unplug_screen_spec.dart';
import 'package:breathefree_patient/unplug/platform/unplug_api.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('catalog', () {
    test('the Unplug module is exactly screens A to L, in order', () {
      expect(unplugScreens, hasLength(12));
      expect(
        unplugScreens.map((screen) => screen.letter),
        orderedEquals(const [
          'A',
          'B',
          'C',
          'D',
          'E',
          'F',
          'G',
          'H',
          'I',
          'J',
          'K',
          'L',
        ]),
      );
      expect(
        unplugScreens.every((screen) => screen.addendumRef.contains('§')),
        isTrue,
        reason: 'every Unplug screen states which addendum section it '
            'implements',
      );
    });

    test('the prototype walks the approved screens, then the Unplug ones', () {
      expect(prototypeCatalog, hasLength(approvedScreens.length + 12));
      expect(unplugCatalogOffset, approvedScreens.length);
      expect(prototypeCatalog[unplugCatalogOffset - 1],
          isA<ApprovedCatalogEntry>());
      expect(prototypeCatalog[unplugCatalogOffset], isA<UnplugCatalogEntry>());
      expect(prototypeCatalog.last.badge, 'L');
    });

    test('letters resolve to catalog positions', () {
      expect(prototypeIndexOfLetter('A'), unplugCatalogOffset);
      expect(prototypeIndexOfLetter('D'), unplugCatalogOffset + 3);
      expect(prototypeIndexOfLetter('Z'), -1);
    });
  });

  group('intercept tokens', () {
    test('the shipped token file parses and carries what the UI reads', () {
      final source =
          File('assets/unplug/intercept_tokens.json').readAsStringSync();
      final tokens = InterceptTokens.parse(source);

      expect(tokens.version, isNotEmpty);
      expect(tokens.color('accent'), isA<Color>());
      expect(tokens.text('title'), isNotEmpty);
      expect(tokens.breathSeconds, greaterThan(0));
      expect(
        tokens.androidLatencyMsMax,
        greaterThanOrEqualTo(tokens.androidLatencyMsMin),
      );
    });

    test('placeholders are substituted', () {
      final source =
          File('assets/unplug/intercept_tokens.json').readAsStringSync();
      final tokens = InterceptTokens.parse(source);

      final rendered =
          tokens.text('overrideRemaining', {'remaining': '2', 'total': '3'});
      expect(rendered, contains('2'));
      expect(rendered, contains('3'));
      expect(rendered, isNot(contains('{')));
    });

    test('a malformed colour is rejected rather than defaulted', () {
      const malformed = '''
      {
        "version": "test",
        "colors": {"accent": "not-a-colour"},
        "copy": {"title": "x"},
        "timing": {
          "breathSeconds": 1,
          "androidOverlayLatencyMsMin": 1,
          "androidOverlayLatencyMsMax": 2
        }
      }
      ''';
      expect(
        () => InterceptTokens.parse(malformed),
        throwsA(isA<FormatException>()),
      );
    });

    test('an unknown copy key throws instead of rendering an empty string', () {
      final source =
          File('assets/unplug/intercept_tokens.json').readAsStringSync();
      final tokens = InterceptTokens.parse(source);
      expect(() => tokens.text('nope'), throwsA(isA<StateError>()));
    });
  });

  group('tier changes', () {
    test('tightening applies at once and clears any pending request', () {
      final state = UnplugModuleState(platform: TrackedPlatform.ios);
      addTearDown(state.dispose);

      state.requestTier(4);
      expect(state.tier, 4);
      expect(state.limitRequest, isNull);
    });

    test('a self-guided loosening waits out a 24-hour cool-off', () {
      final state = UnplugModuleState(platform: TrackedPlatform.ios)
        ..selectTrack(DeliveryTrack.selfGuided);
      addTearDown(state.dispose);

      final at = DateTime(2026, 3, 1, 9);
      state.requestTier(0, now: at);

      expect(state.tier, 2, reason: 'nothing loosens before the cool-off');
      expect(state.limitRequest, isNotNull);
      expect(state.limitRequest!.reviewer, isNull);
      expect(state.limitRequest!.clearsAt, at.add(selfGuidedCoolOff));

      state.settleLimitRequest(now: at.add(const Duration(hours: 23)));
      expect(state.tier, 2, reason: 'the cool-off has not expired');

      state.settleLimitRequest(now: at.add(const Duration(hours: 24)));
      expect(state.tier, 0);
      expect(state.limitRequest, isNull);
    });

    test('a clinician loosening waits for a reviewer, not a clock', () {
      final state = UnplugModuleState(platform: TrackedPlatform.ios)
        ..selectTrack(DeliveryTrack.clinician);
      addTearDown(state.dispose);

      state.requestTier(1);
      expect(state.limitRequest, isNotNull);
      expect(state.limitRequest!.clearsAt, isNull);
      expect(state.limitRequest!.reviewer, isNotNull);

      state.settleLimitRequest();
      expect(state.tier, 1, reason: 'a reviewer can settle it immediately');
    });

    test('a template clamps the tier range and sets the track', () {
      final state = UnplugModuleState(platform: TrackedPlatform.ios);
      addTearDown(state.dispose);

      final familyReset = programTemplates.first;
      state
        ..requestTier(5)
        ..applyTemplate(familyReset);

      expect(state.track, familyReset.track);
      expect(state.tierCeiling, familyReset.highestTier);
      expect(state.tier, lessThanOrEqualTo(familyReset.highestTier));
      expect(state.selfMayMoveTier, isFalse,
          reason: 'the under-13 template gives the guardian every limit');
    });
  });

  group('distress routing', () {
    test('two distress tags in a row open the escalation route', () {
      final state = UnplugModuleState(platform: TrackedPlatform.ios)
        ..selectTrack(DeliveryTrack.coach);
      addTearDown(state.dispose);

      final anxious = urgeTags.firstWhere((tag) => tag.distress);
      final bored = urgeTags.firstWhere((tag) => !tag.distress);

      state.tagUrge(bored);
      expect(state.escalationOpened, isFalse);

      state.tagUrge(anxious);
      expect(state.escalationOpened, isFalse);

      state.tagUrge(anxious);
      expect(state.escalationOpened, isTrue);
    });

    test('no track absorbs a distress signal without naming a route', () {
      for (final track in DeliveryTrack.values) {
        expect(distressRouteFor(track), isNotEmpty);
      }
      expect(
        distressRouteFor(DeliveryTrack.coach).toLowerCase(),
        contains('clinician'),
        reason: 'addendum §4.1 — distress never terminates at a coach',
      );
    });
  });

  group('authorization', () {
    test('iOS without Family Sharing cannot be authorized at all', () {
      final state = UnplugModuleState(platform: TrackedPlatform.ios)
        ..setFamilySharing(FamilySharingState.missing)
        ..requestAuthorization();
      addTearDown(state.dispose);

      expect(state.authorization,
          AuthorizationState.blockedNoFamilySharing);
      expect(state.authorization.isUsable, isFalse);
    });

    test('Android is unaffected by Family Sharing', () {
      final state = UnplugModuleState(platform: TrackedPlatform.android)
        ..setFamilySharing(FamilySharingState.missing)
        ..requestAuthorization();
      addTearDown(state.dispose);

      expect(state.authorization, AuthorizationState.approved);
    });

    test('a child device pairs only once Family Sharing is set up', () {
      final state = UnplugModuleState(platform: TrackedPlatform.ios)
        ..setFamilySharing(FamilySharingState.missing)
        ..pairChildProfile();
      addTearDown(state.dispose);

      expect(state.childProfilePaired, isFalse);

      state
        ..setFamilySharing(FamilySharingState.configured)
        ..pairChildProfile();
      expect(state.childProfilePaired, isTrue);
    });
  });

  group('overrides', () {
    test('the allowance is spent, not exceeded', () {
      final state = UnplugModuleState(platform: TrackedPlatform.ios)
        ..setOverrideAllowance(2);
      addTearDown(state.dispose);

      expect(state.useOverride(), isTrue);
      expect(state.useOverride(), isTrue);
      expect(state.useOverride(), isFalse);
      expect(state.overridesLeft, 0);

      state.resetOverrides();
      expect(state.overridesLeft, 2);
    });
  });

  group('tracking health', () {
    test('checks are filtered to the platform they apply to', () {
      final state = UnplugModuleState(platform: TrackedPlatform.ios);
      addTearDown(state.dispose);

      expect(state.trackingHealthy, isTrue);
      final iosChecks = state.applicableChecks.map((check) => check.name);
      expect(iosChecks, contains('App Group container'));
      expect(iosChecks, isNot(contains('Overlay permission')));

      state.selectPlatform(TrackedPlatform.android);
      final androidChecks = state.applicableChecks.map((check) => check.name);
      expect(androidChecks, contains('Overlay permission'));
      expect(androidChecks, isNot(contains('App Group container')));
    });

    test('one failed check reports tracking as stopped', () {
      final state = UnplugModuleState(platform: TrackedPlatform.android)
        ..toggleCheck('Foreground service alive');
      addTearDown(state.dispose);

      expect(state.trackingHealthy, isFalse);

      state.restoreTracking();
      expect(state.trackingHealthy, isTrue);
    });
  });

  group('module UI', () {
    testWidgets('the phone view opens Unplug screen A after the approved 28',
        (tester) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        BreatheFreeApp(initialScreen: unplugCatalogOffset),
      );
      await tester.pump();

      expect(find.text('What this can see'), findsOneWidget);
      expect(find.text('Screen 1 of 12'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the platform toggle rewrites what screen A claims',
        (tester) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        BreatheFreeApp(initialScreen: unplugCatalogOffset),
      );
      await tester.pump();

      // `flutter test` reports Android as the default target platform, so the
      // module opens on the column that can name apps.
      expect(
        find.textContaining('On Android the usage API'),
        findsOneWidget,
      );

      await tester.tap(find.text('iOS'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('opaque, device-local tokens'),
        findsOneWidget,
      );
      expect(find.textContaining('On Android the usage API'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the desktop shell lists both modules', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        BreatheFreeApp(initialScreen: unplugCatalogOffset),
      );
      await tester.pump();

      expect(find.text('28 approved screens'), findsOneWidget);
      expect(find.text('Screen A · What this can see'), findsOneWidget);
      expect(
        find.text('Addendum §1'),
        findsOneWidget,
        reason: 'the details panel sources an Unplug screen to the addendum',
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('child profile lockdown (§3.2)', () {
    UnplugModuleState childProfile() {
      final state = UnplugModuleState(platform: TrackedPlatform.ios)
        ..setFamilySharing(FamilySharingState.configured)
        ..pairChildProfile();
      return state;
    }

    test('pairing a child profile turns the lockdown on', () {
      final state = childProfile();
      addTearDown(state.dispose);
      expect(state.childLockdownActive, isTrue);
    });

    test('the typed commitment is withdrawn, because typing is free text', () {
      final state = UnplugModuleState(platform: TrackedPlatform.ios)
        ..selectGate(EffortGateChoice.commitment);
      addTearDown(state.dispose);

      expect(state.availableGates, EffortGateChoice.values);
      expect(state.gate, EffortGateChoice.commitment);

      state
        ..setFamilySharing(FamilySharingState.configured)
        ..pairChildProfile();

      expect(state.availableGates, isNot(contains(EffortGateChoice.commitment)));
      expect(
        state.gate,
        EffortGateChoice.breath,
        reason: 'the selected gate must fall back, not stay on a gate the '
            'intercept will no longer offer',
      );
    });

    test('every child-safe list is non-empty and free of blanks', () {
      for (final list in [childSafeGroupLabels, childSafeSessionReasons]) {
        expect(list, isNotEmpty);
        expect(list.every((entry) => entry.trim().isNotEmpty), isTrue);
      }
    });

    test('retention on a child profile is the 30 days the addendum sets', () {
      expect(childRetentionDays, 30);
    });
  });

  group('platform binding', () {
    test('an unbound module is not live and says so', () {
      final state = UnplugModuleState(platform: TrackedPlatform.ios);
      addTearDown(state.dispose);
      expect(state.isLive, isFalse);
      expect(state.liveUsage, isNull);
      expect(state.channelFailure, isNull);
    });

    test('platform callbacks fold into the state', () {
      final state = UnplugModuleState(platform: TrackedPlatform.android)
        ..setOverrideAllowance(3);
      addTearDown(state.dispose);

      state
        ..applyInterceptShown('Video apps')
        ..applyInterceptShown('Video apps')
        ..applyInterceptDismissed('Video apps')
        ..applyOverrideUsed(1)
        ..applyThresholdCrossed(95, 40);

      expect(state.interceptsShown, 2);
      expect(state.interceptsDismissed, 1);
      expect(state.overridesUsed, 2, reason: '3 allowed, 1 remaining');
      expect(state.lastThreshold?.minutes, 95);
      expect(state.lastThreshold?.opens, 40);
    });

    test('a platform authorization result overrides the optimistic guess', () {
      final state = UnplugModuleState(platform: TrackedPlatform.ios);
      addTearDown(state.dispose);

      state.applyPlatformAuthorization(
        PlatformAuthorizationStatus.blockedNoFamilySharing,
      );
      expect(state.authorization, AuthorizationState.blockedNoFamilySharing);

      state.applyPlatformAuthorization(PlatformAuthorizationStatus.approved);
      expect(state.authorization, AuthorizationState.approved);
    });

    test('platform-reported checks replace the built-in ones', () {
      final state = UnplugModuleState(platform: TrackedPlatform.ios);
      addTearDown(state.dispose);

      state.applyPlatformChecks([
        PlatformTrackingCheck(
          name: 'Screen-time authorization',
          healthy: false,
          detail: 'Screen Time access is not granted.',
        ),
      ]);

      expect(state.trackingHealthy, isFalse);
      expect(state.applicableChecks, hasLength(1));
      expect(
        state.applicableChecks.single.remedy,
        isNotEmpty,
        reason: 'a failing check must still tell the person what to do',
      );
    });

    test('a channel failure is surfaced, not swallowed', () {
      final state = UnplugModuleState(platform: TrackedPlatform.ios);
      addTearDown(state.dispose);
      expect(state.channelFailure, isNull);
      state.applyChannelFailure('applyShield', 'MissingPluginException');
      expect(state.channelFailure, contains('applyShield'));
    });
  });
}
