import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/screen_spec.dart';
import '../../models/tap_target.dart';
import '../../widgets/approved_screen_viewport.dart';
import '../journey/journey.dart';
import '../theme/tether_tokens.dart';
import '../widgets/call_affordance.dart';
import '../../config/contact_info.dart';
import 'shell/shell_routes.dart';

/// A screen that was signed off as a picture.
///
/// BreatheFree's 28 screens are approved 1290 × 2796 artwork, and the design
/// bundle ships no content file for them because there is nothing to fill —
/// the design *is* the image. Before this renderer existed the shell drew all
/// 23 of them as unwritten stubs, which stated a gap that does not exist: the
/// most reviewed screens in the product were the ones the app claimed were
/// missing.
///
/// So the shell shows the artwork. The same [ApprovedScreenViewport] the
/// standalone prototype uses draws it, which means the invisible tap targets
/// come along too and the screen is as interactive here as it is there.
class ArtworkScreen extends StatefulWidget {
  const ArtworkScreen({
    required this.screen,
    required this.journey,
    required this.onNavigate,
    super.key,
  });

  final JourneyScreen screen;
  final Journey journey;

  /// Screen-id navigation, for parity with the other renderers. The artwork's
  /// own tap targets address approved screens by index, not by product id, so
  /// this is used only by the chrome.
  final ValueChanged<String> onNavigate;

  @override
  State<ArtworkScreen> createState() => _ArtworkScreenState();
}

class _ArtworkScreenState extends State<ArtworkScreen> {
  JourneyScreen get screen => widget.screen;
  Journey get journey => widget.journey;
  ValueChanged<String> get onNavigate => widget.onNavigate;

  @override
  void initState() {
    super.initState();
    // The artwork is a full-bleed 1290 × 2796 render of a whole phone screen,
    // and it has a status bar painted into it — 9:41, full signal, the usual.
    // Leaving the real one on top of it shows two clocks, an hour apart. The
    // system bars come back in dispose, because everywhere else in the shell
    // is a real app and should keep them.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// The approved screen this maps to, or null when the number is outside the
  /// 28 that exist.
  ScreenSpec? get _spec {
    final number = screen.approvedScreen;
    if (number == null) return null;
    for (final spec in approvedScreens) {
      if (spec.number == number) return spec;
    }
    return null;
  }

  /// Moves within the artwork by approved-screen number rather than by
  /// product screen id.
  ///
  /// The two numbering schemes agree where they overlap, but the product lists
  /// 23 of the 28 — so stepping off the end of the product's list is normal
  /// and lands nowhere rather than crashing.
  void _step(BuildContext context, int delta) {
    final spec = _spec;
    if (spec == null) return;
    final target = spec.number + delta;
    if (target < 1 || target > JourneyBuilder.approvedScreenCount) return;

    final id = 'S${target.toString().padLeft(2, '0')}';
    if (journey.screen(id) == null) return;
    onNavigate(id);
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    if (spec == null) {
      // Unreachable through JourneyScreenHost, which only routes here when a
      // number exists. Kept as a visible statement rather than a crash.
      return Scaffold(
        backgroundColor: TetherColors.cream,
        appBar: AppBar(title: Text(screen.title)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This screen is approved artwork, but no image matches its '
              'number.',
              textAlign: TextAlign.center,
              style: TetherText.cardBody,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      // The artwork is drawn on its own background and carries its own
      // chrome — a header, a back control, a footer. Wrapping it in the
      // shell's top bar would give the screen two of each.
      backgroundColor: TetherColors.ink,
      body: Stack(
        children: [
          Positioned.fill(
            child: ApprovedScreenViewport(
              spec: spec,
              onPrevious: () => _step(context, -1),
              onNext: () => _step(context, 1),
              onTarget: (target) => _handle(context, target),
            ),
          ),
          // One way back into the shell.
          //
          // Bottom-right, not top-right: the artwork paints its own status
          // row, title and status pill across the top, and anything floated up
          // there lands on one of them. The bottom-right corner is the only
          // part of a 1290 × 2796 render that is reliably empty — the approved
          // screens centre their footers and their primary buttons stop short
          // of the corner.
          //
          // The artwork's own back control is left alone and still works; it
          // pops this route through [_handle]. This exists for screen 1, which
          // has no back target because in the original flow there was nothing
          // behind it.
          Positioned(
            bottom: 8,
            right: 8,
            child: _LeaveButton(onPressed: () => Navigator.of(context).pop()),
          ),
        ],
      ),
    );
  }

  /// Handles a tap on one of the artwork's invisible targets.
  ///
  /// Navigation is translated into the shell's own routing so the back stack
  /// stays coherent. The rest do the same thing the standalone prototype does,
  /// because these are approved interactions and the shell showing the same
  /// artwork should not answer them differently — a reviewer comparing the two
  /// builds would be right to call that a defect.
  ///
  /// What none of them do is pretend. There is no dialler, no export service
  /// and no account to delete in this build, and each dialog says so.
  void _handle(BuildContext context, AppTapTarget target) {
    switch (target.action) {
      case TapAction.navigate:
        final destination = target.destination;
        if (destination == null) return;
        final id = 'S${(destination + 1).toString().padLeft(2, '0')}';
        if (journey.screen(id) == null) return;
        onNavigate(id);

      case TapAction.back:
        Navigator.of(context).maybePop();

      case TapAction.quitline:
        // The same route every other number in the app takes. The line comes
        // from the target rather than being hardcoded here, so a Spanish
        // target reaches the Spanish quitline instead of the English one.
        final line = target.quitline ?? ContactInfo.english;
        CallAffordance.offer(
          context,
          name: line.vanityNumber,
          number: line.dialledNumber,
        );

      case TapAction.contactSupport:
        // Product support, not a clinician, and the copy has to say so:
        // somebody with urgent symptoms must not be left waiting on an inbox.
        _explain(
          context,
          title: 'Contact support',
          body: 'For questions about the app, your account or your data, '
              'email ${ContactInfo.supportEmail}. That inbox is not monitored '
              'for medical emergencies and cannot give medical advice. In an '
              'emergency call ${ContactInfo.emergencyNumber}.',
          confirmLabel: 'Get help now',
          onConfirm: () => Navigator.of(context).pushNamed(ShellRoutes.crisis),
        );

      case TapAction.callbackConsent:
        _explain(
          context,
          title: 'Request a counselor call-back?',
          body: 'Before sending a referral, the production app will show the '
              'exact contact details, purpose, destination and consent '
              'expiration. Nothing is sent from this build.',
        );

      case TapAction.exportData:
        // The shell owns the real one, and it works: SH4 exports everything
        // across every program. Sending the person there beats showing them a
        // second, weaker version of the same action.
        _explain(
          context,
          title: 'Prepare your data copy?',
          body: 'Your record is the one place this app exports from, and it '
              'covers every program rather than this one.',
          confirmLabel: 'Open your record',
          onConfirm: () =>
              Navigator.of(context).pushNamed(ShellRoutes.record),
        );

      case TapAction.deleteAccount:
        _explain(
          context,
          title: 'Delete account and data?',
          body: 'Deletion lives in your record, where it can state exactly '
              'what goes. A production build must also require recent '
              'authentication before it runs.',
          confirmLabel: 'Open your record',
          onConfirm: () =>
              Navigator.of(context).pushNamed(ShellRoutes.record),
        );

      case TapAction.information:
        _explain(
          context,
          title: target.label,
          body: 'This interaction is part of the approved design. It is drawn '
              'here as artwork and is not connected to a service in this '
              'build.',
        );
    }
  }

  /// A dialog that explains rather than performs.
  Future<void> _explain(
    BuildContext context, {
    required String title,
    required String body,
    String? confirmLabel,
    VoidCallback? onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(confirmLabel == null ? 'Done' : 'Cancel'),
          ),
          if (confirmLabel != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onConfirm?.call();
              },
              child: Text(confirmLabel),
            ),
        ],
      ),
    );
  }
}

/// Leaves the artwork and returns to the shell.
class _LeaveButton extends StatelessWidget {
  const _LeaveButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Leave',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
