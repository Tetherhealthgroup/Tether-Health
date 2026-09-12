import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/platform_ceiling.dart';
import '../models/unplug_module_state.dart';
import '../widgets/unplug_kit.dart';
import '../widgets/unplug_scope.dart';

/// Screen J — the guardian zone, and the under-13 path (addendum §3).
///
/// The expensive part of this screen is not the UI, it is the honest failure
/// state. Shielding a child's device on iOS needs `requestAuthorization(.child)`,
/// which needs the child in an iCloud Family and the parent's Screen Time
/// passcode entered on the child's device. Where a household has not set Family
/// Sharing up, this path does not work and no amount of engineering fixes it —
/// so the screen says that instead of retrying.
class UnplugScreenJ extends StatefulWidget {
  const UnplugScreenJ({required this.nav, super.key});

  final UnplugNavigation nav;

  @override
  State<UnplugScreenJ> createState() => _UnplugScreenJState();
}

class _UnplugScreenJState extends State<UnplugScreenJ> {
  late final String _pairingCode = _makeCode();

  static String _makeCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final letters = List.generate(
      6,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
    return '${letters.substring(0, 3)}-${letters.substring(3)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = UnplugScope.of(context);
    final onIos = state.platform == TrackedPlatform.ios;

    return UnplugPage(
      nav: widget.nav,
      children: [
        const UnplugSection(
          title: 'Account model',
          child: UnplugCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The child does not get an account.',
                  style: TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'A guardian’s Tether account holds a child profile, and the '
                  'child’s device is paired to that profile with a code. '
                  'Verifiable parental consent runs through Tether’s existing '
                  'minor-enrollment flow — a second consent mechanism built '
                  'here would be a second thing to keep compliant.',
                  style: TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onIos) ...[
          UnplugSection(
            title: 'Family Sharing',
            trailing: UnplugPill(
              label: state.familySharing.label,
              background:
                  state.familySharing == FamilySharingState.configured
                      ? AppColors.mint
                      : state.familySharing == FamilySharingState.missing
                          ? AppColors.coralLight
                          : AppColors.mintStrong,
              foreground: state.familySharing == FamilySharingState.missing
                  ? const Color(0xFF8C3A26)
                  : AppColors.deepTeal,
            ),
            child: UnplugChoices<FamilySharingState>(
              values: FamilySharingState.values,
              selected: state.familySharing,
              labelOf: (value) => value.label,
              onSelected: state.setFamilySharing,
            ),
          ),
          if (state.familySharing == FamilySharingState.missing)
            const UnplugNote(
              tone: NoteTone.warning,
              text: 'Without an iCloud Family this device cannot be shielded '
                  'as a child device on iOS at all. The steps below are the '
                  'only route, and they happen in Apple’s Settings, not here. '
                  'Expect this to be the largest onboarding drop-off on iOS.',
            ),
          if (state.familySharing != FamilySharingState.configured)
            const UnplugSection(
              title: 'Set it up first',
              child: UnplugCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Step(
                      number: 1,
                      text: 'On the guardian’s iPhone, open Settings, tap the '
                          'name at the top, then Family.',
                    ),
                    _Step(
                      number: 2,
                      text: 'Add the child to the family group, or create a '
                          'child Apple Account for them there.',
                    ),
                    _Step(
                      number: 3,
                      text: 'On the child’s device, sign in with that child '
                          'Apple Account.',
                    ),
                    _Step(
                      number: 4,
                      text: 'Set a Screen Time passcode on the child’s device '
                          'and keep it with the guardian, not the child.',
                    ),
                    _Step(
                      number: 5,
                      text: 'Come back and request authorization. The system '
                          'prompt asks for the guardian’s Apple Account and '
                          'that passcode.',
                      last: true,
                    ),
                  ],
                ),
              ),
            ),
        ] else
          const UnplugNote(
            text: 'Android has no Family Sharing prerequisite. The guardian '
                'grants usage access and the overlay permission on the child’s '
                'device directly, and the pairing code below is the whole '
                'setup.',
          ),
        UnplugSection(
          title: 'Pair the child’s device',
          child: UnplugCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pairingCode,
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 32,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.childProfilePaired
                      ? 'Paired. The child profile is active on this device.'
                      : 'Enter this on the child’s device to attach it to the '
                          'child profile.',
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.childProfilePaired ||
                            (onIos &&
                                state.familySharing !=
                                    FamilySharingState.configured)
                        ? null
                        : state.pairChildProfile,
                    child: Text(
                      state.childProfilePaired ? 'Paired' : 'Confirm pairing',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const UnplugSection(
          title: 'What the child profile locks down',
          child: UnplugCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Lockdown(
                  text: 'No free-text fields anywhere. No journal, no custom '
                      'intentions, no names — pick-from-list only.',
                ),
                _Lockdown(text: 'No streaks, no comparisons, nothing sharable.'),
                _Lockdown(
                  text: 'Thirty days of on-device retention. Only aggregate '
                      'adherence syncs.',
                ),
                _Lockdown(
                  text: 'No third-party SDKs. No analytics, no crash reporters '
                      'that collect identifiers, no session replay — including '
                      'through a transitive dependency.',
                  last: true,
                ),
              ],
            ),
          ),
        ),
        const UnplugNote(
          text: 'This is not submitted to Apple’s Kids Category or Google’s '
              'Designed for Families programme. Those are for apps children '
              'find and install themselves. This is a health app a guardian '
              'installs that happens to carry a child profile, and the review '
              'path is much simpler when it is positioned that way.',
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text, this.last = false});

  final int number;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.deepTeal,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Lockdown extends StatelessWidget {
  const _Lockdown({required this.text, this.last = false});

  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 17,
            color: AppColors.deepTeal,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
