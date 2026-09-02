import 'dart:ui';

import '../config/contact_info.dart';

enum TapAction {
  navigate,
  back,
  quitline,
  callbackConsent,
  exportData,
  deleteAccount,
  contactSupport,
  information,
}

class AppTapTarget {
  const AppTapTarget({
    required this.normalizedRect,
    required this.label,
    required this.action,
    this.destination,
    this.quitline,
  });

  final Rect normalizedRect;
  final String label;
  final TapAction action;
  final int? destination;

  /// Which quitline a [TapAction.quitline] target dials.
  ///
  /// The Support hub offers an English and a Spanish line, so the action alone
  /// does not say which one was tapped.
  final QuitlineContact? quitline;
}

/// Top edge of the five-tab bar, as a fraction of screen height.
const double _tabBarTop = 0.875;

List<AppTapTarget> tapTargetsFor(int index) {
  final number = index + 1;
  final targets = <AppTapTarget>[];

  // Screens 12-27 carry the tab bar; anything above it must stop short of it.
  final hasTabBar = number >= 12 && number <= 27;

  if (number > 1) {
    targets.add(
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.03, 0.035, 0.14, 0.075),
        label: 'Go back',
        action: TapAction.back,
      ),
    );
  }

  if (number <= 11 || (number >= 13 && number <= 21)) {
    // On tab-bar screens this stopped at 0.89 and so ran 0.015 underneath the
    // tab bar, which is added later and therefore won the hit test. The
    // primary action silently lost its lowest strip of touch area.
    const double top = 0.72;
    targets.add(
      AppTapTarget(
        normalizedRect: Rect.fromLTWH(
          0.05,
          top,
          0.90,
          hasTabBar ? _tabBarTop - top : 0.17,
        ),
        label: number == 1 ? 'Get started' : 'Continue to the next step',
        action: TapAction.navigate,
        destination: (index + 1).clamp(0, 27).toInt(),
      ),
    );
  }

  if (number == 12 || number == 22) {
    targets.addAll([
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.05, 0.29, 0.90, 0.20),
        label: 'Open craving rescue',
        action: TapAction.navigate,
        destination: 16,
      ),
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.05, 0.50, 0.90, 0.13),
        label: 'Start daily check-in',
        action: TapAction.navigate,
        destination: 12,
      ),
    ]);
  }

  if (number == 22) {
    targets.add(
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.05, 0.67, 0.90, 0.10),
        label: 'Report a slip without losing progress',
        action: TapAction.navigate,
        destination: 22,
      ),
    );
  }

  if (number == 23) {
    targets.add(
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.05, 0.70, 0.90, 0.14),
        label: 'Return to quit-day home',
        action: TapAction.navigate,
        destination: 21,
      ),
    );
  }

  if (number == 27) {
    // Rectangles below are derived from the group transforms in
    // design/approved/screen-27-support-hub-iphone.svg, divided by the
    // 1290 x 2796 artboard.
    targets.addAll([
      AppTapTarget(
        normalizedRect: const Rect.fromLTWH(0.05, 0.14, 0.61, 0.17),
        label: 'Call ${ContactInfo.english.vanityNumber}',
        action: TapAction.quitline,
        quitline: ContactInfo.english,
      ),
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.66, 0.18, 0.29, 0.08),
        label: 'Request a counselor call-back',
        action: TapAction.callbackConsent,
      ),
      // "Ayuda en español" card, translate(72 962), height 111. The artwork
      // has always drawn this line; nothing reached it before.
      AppTapTarget(
        normalizedRect: const Rect.fromLTWH(0.05, 0.34, 0.89, 0.04),
        label: 'Call ${ContactInfo.spanish.vanityNumber}',
        action: TapAction.quitline,
        quitline: ContactInfo.spanish,
      ),
      // Supporter row, translate(72 1179) + translate(35 30).
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.05, 0.432, 0.89, 0.055),
        label: 'Message or call your supporter',
        action: TapAction.information,
      ),
      // Quit-coach row, translate(72 1179) + translate(35 247).
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.05, 0.508, 0.89, 0.05),
        label: 'Send a secure message to your quit coach',
        action: TapAction.information,
      ),
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.05, 0.75, 0.90, 0.10),
        label: 'Open sharing controls',
        action: TapAction.navigate,
        destination: 27,
      ),
    ]);
  }

  if (number == 28) {
    targets.addAll([
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.05, 0.61, 0.90, 0.06),
        label: 'Download a copy of your data',
        action: TapAction.exportData,
      ),
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.05, 0.70, 0.90, 0.06),
        label: 'Delete account and data',
        action: TapAction.deleteAccount,
      ),
      // Accessibility card, translate(72 2221), height 321. Reachable now:
      // settings that exist to help disabled users must not themselves be
      // unreachable.
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.05, 0.79, 0.89, 0.115),
        label: 'Open accessibility settings',
        action: TapAction.information,
      ),
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.05, 0.92, 0.90, 0.05),
        label: 'Sign out',
        action: TapAction.information,
      ),
    ]);
  }

  if (number >= 12 && number <= 27) {
    final homeDestination = number >= 22 ? 21 : 11;
    targets.addAll([
      AppTapTarget(
        normalizedRect: const Rect.fromLTWH(0.00, _tabBarTop, 0.20, 0.11),
        label: 'Home tab',
        action: TapAction.navigate,
        destination: homeDestination,
      ),
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.20, _tabBarTop, 0.20, 0.11),
        label: 'Plan tab',
        action: TapAction.navigate,
        destination: 10,
      ),
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.40, _tabBarTop, 0.20, 0.11),
        label: 'Progress tab',
        action: TapAction.navigate,
        destination: 25,
      ),
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.60, _tabBarTop, 0.20, 0.11),
        label: 'Learn tab',
        action: TapAction.navigate,
        destination: 24,
      ),
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.80, _tabBarTop, 0.20, 0.11),
        label: 'Support tab',
        action: TapAction.navigate,
        destination: 26,
      ),
      const AppTapTarget(
        normalizedRect: Rect.fromLTWH(0.85, 0.035, 0.13, 0.075),
        label: 'Open settings and privacy',
        action: TapAction.navigate,
        destination: 27,
      ),
    ]);
  }

  return targets;
}
