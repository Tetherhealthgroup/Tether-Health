// The tether_ui app's entry screen: the first matching rule wins.
import 'package:breathefree_patient/app/entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/routes.dart';

void main() {
  group('resolveEntry', () {
    test('1. a pending deletion receipt opens account_deleted', () {
      expect(
        resolveEntry(const EntryState(
          pendingDeletionReceipt: true,
          passwordRecoveryPending: true,
          minimumBuild: 9,
          installedBuild: 2,
          signedIn: true,
          onboardingComplete: true,
          guestPlanPresent: true,
        )),
        Routes.accountDeleted,
      );
    });

    test('2. a pending password recovery opens auth_newpass', () {
      expect(
        resolveEntry(const EntryState(
          passwordRecoveryPending: true,
          minimumBuild: 9,
          installedBuild: 2,
          signedIn: true,
          guestPlanPresent: true,
        )),
        Routes.authNewpass,
      );
    });

    test('3. a minimum build above the installed one opens sys_update', () {
      expect(
        resolveEntry(const EntryState(
          minimumBuild: 3,
          installedBuild: 2,
          signedIn: true,
          guestPlanPresent: true,
        )),
        Routes.sysUpdate,
      );
      expect(
        resolveEntry(const EntryState(minimumBuild: 2, installedBuild: 2)),
        Routes.welcome,
      );
    });

    test('3. without a minimum build source the update rule is skipped', () {
      expect(resolveEntry(const EntryState(installedBuild: 2)), Routes.welcome);
      expect(resolveEntry(const EntryState(minimumBuild: 9)), Routes.welcome);
    });

    test('4. signed in with onboarding complete opens today', () {
      expect(
        resolveEntry(
            const EntryState(signedIn: true, onboardingComplete: true)),
        Routes.today,
      );
    });

    test('4. signed in with onboarding not yet known opens today', () {
      expect(resolveEntry(const EntryState(signedIn: true)), Routes.today);
    });

    test('5. a guest plan opens today', () {
      expect(
          resolveEntry(const EntryState(guestPlanPresent: true)), Routes.today);
    });

    test('6. otherwise welcome', () {
      expect(resolveEntry(const EntryState()), Routes.welcome);
    });

    test('6. signed in with onboarding known incomplete opens welcome', () {
      expect(
        resolveEntry(
            const EntryState(signedIn: true, onboardingComplete: false)),
        Routes.welcome,
      );
    });

    test('a guest plan does not override a known incomplete onboarding', () {
      // Rule 5 still applies: the guest plan opens today.
      expect(
        resolveEntry(const EntryState(
          signedIn: true,
          onboardingComplete: false,
          guestPlanPresent: true,
        )),
        Routes.today,
      );
    });

    test('is pure: the same state gives the same route', () {
      const state = EntryState(signedIn: true);
      expect(resolveEntry(state), resolveEntry(state));
      expect(state, const EntryState(signedIn: true));
      expect(state.hashCode, const EntryState(signedIn: true).hashCode);
    });
  });
}
