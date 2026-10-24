import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/intercept_tokens.dart';
import '../models/platform_ceiling.dart';
import '../models/unplug_module_state.dart';
import '../widgets/unplug_kit.dart';
import '../widgets/unplug_scope.dart';

/// Screen C — the Dart preview of the intercept.
///
/// Addendum §2.1: this screen exists three times. The shipped iOS intercept is
/// drawn by a `ShieldConfiguration` extension in SwiftUI and the Android one by
/// an overlay service, because neither can run Flutter. This Dart copy is the
/// in-app preview and the settings preview, and all three read
/// `assets/unplug/intercept_tokens.json` so they cannot drift apart.
class UnplugScreenC extends StatelessWidget {
  const UnplugScreenC({required this.nav, this.onOpenEffortGate, super.key});

  final UnplugNavigation nav;

  /// Opens screen D, the effort gate.
  final VoidCallback? onOpenEffortGate;

  @override
  Widget build(BuildContext context) {
    final state = UnplugScope.of(context);
    final tokens = state.tokens;

    return UnplugPage(
      nav: nav,
      children: [
        UnplugSection(
          title: 'Preview',
          trailing: tokens == null
              ? null
              : UnplugPill(label: 'Tokens v${tokens.version}'),
          child: tokens == null
              ? _TokenProblem(state: state)
              : _InterceptPreview(
                  tokens: tokens,
                  state: state,
                  onOpenEffortGate: onOpenEffortGate,
                ),
        ),
        const UnplugSection(
          title: 'Where this is built',
          child: Column(
            children: [
              _BuildRow(
                platform: 'Dart',
                what: 'This preview, and the settings preview.',
                status: 'Built',
                built: true,
              ),
              _BuildRow(
                platform: 'SwiftUI',
                what: 'ShieldConfiguration extension. Separate process, tight '
                    'memory budget, cannot run Flutter.',
                status: 'Not yet implemented',
                built: false,
              ),
              _BuildRow(
                platform: 'Android overlay',
                what: 'Foreground service plus SYSTEM_ALERT_WINDOW. Appears '
                    '0.5–1.5s after the app comes to the foreground.',
                status: 'Not yet implemented',
                built: false,
              ),
            ],
          ),
        ),
        const UnplugNote(
          text: 'Colours and copy come from '
              'assets/unplug/intercept_tokens.json. Change them there and all '
              'three implementations move together; change them in a widget '
              'and the three drift apart within two sprints.',
        ),
        if (state.platform == TrackedPlatform.android && tokens != null)
          UnplugNote(
            text: 'Android reaches this screen by polling usage stats rather '
                'than by an accessibility service, so it appears '
                '${tokens.androidLatencyMsMin}–${tokens.androidLatencyMsMax}ms '
                'after the app opens. A second of delay is a minor cost; a '
                'removed app is a dead program.',
          ),
      ],
    );
  }
}

class _TokenProblem extends StatelessWidget {
  const _TokenProblem({required this.state});

  final UnplugModuleState state;

  /// Re-reads the shared token file without restarting the app.
  ///
  /// A corrupt file usually means a bad asset bundle rather than a transient
  /// failure, but re-reading is free and the alternative is a dead screen
  /// until the next launch.
  Future<void> _retry() async {
    try {
      state.setTokens(await InterceptTokens.load());
    } catch (error) {
      state.setTokenError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = state.tokenError;
    if (error == null) {
      return const UnplugCard(
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Reading the shared intercept tokens…'),
          ],
        ),
      );
    }

    return UnplugCard(
      color: AppColors.coralLight,
      borderColor: AppColors.coral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The shared intercept token file could not be read.',
            style: TextStyle(
              color: Color(0xFF8C3A26),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            style: const TextStyle(
              color: Color(0xFF8C3A26),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No default is substituted. A default here would hide the same '
            'failure from the SwiftUI and Android implementations, which read '
            'the same file.',
            style: TextStyle(
              color: Color(0xFF8C3A26),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: _retry,
              child: const Text('Try again'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterceptPreview extends StatelessWidget {
  const _InterceptPreview({
    required this.tokens,
    required this.state,
    required this.onOpenEffortGate,
  });

  final InterceptTokens tokens;
  final UnplugModuleState state;
  final VoidCallback? onOpenEffortGate;

  String get _groupLabel {
    final shielded = state.groups.where((group) => group.shielded);
    if (shielded.isEmpty) return 'a shielded app';
    return shielded.first.label;
  }

  @override
  Widget build(BuildContext context) {
    final exhausted = state.overridesLeft == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
      decoration: BoxDecoration(
        color: tokens.color('background'),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.color('accent'),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pause_rounded,
              color: tokens.color('onAccent'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tokens.text('title'),
            style: TextStyle(
              color: tokens.color('onBackground'),
              fontSize: 26,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tokens.text('body'),
            style: TextStyle(
              color: tokens.color('onSurfaceMuted'),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: tokens.color('surface'),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tokens.text('reasonLabel').toUpperCase(),
                  style: TextStyle(
                    color: tokens.color('accent'),
                    fontSize: 10.5,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_groupLabel is on your list at tier ${state.tier}.',
                  style: TextStyle(
                    color: tokens.color('onBackground'),
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: tokens.color('accent'),
                foregroundColor: tokens.color('onAccent'),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onOpenEffortGate,
              child: Text(tokens.text('breatheAction')),
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.color('onBackground'),
                side: BorderSide(color: tokens.color('onSurfaceMuted')),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Shield held. The app stays closed.'),
                ),
              ),
              child: Text(tokens.text('closeAction')),
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: exhausted
                    ? tokens.color('onSurfaceMuted')
                    : tokens.color('danger'),
              ),
              onPressed: exhausted
                  ? null
                  : () {
                      final messenger = ScaffoldMessenger.of(context);
                      state.useOverride();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Override recorded. '
                            '${state.overridesLeft} left in this window.',
                          ),
                        ),
                      );
                    },
              child: Text(tokens.text('overrideAction')),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            exhausted
                ? tokens.text('overrideExhausted')
                : tokens.text('overrideRemaining', {
                    'remaining': '${state.overridesLeft}',
                    'total': '${state.overrideAllowance}',
                  }),
            style: TextStyle(
              color: tokens.color('onSurfaceMuted'),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (state.session?.strict ?? false) ...[
            const SizedBox(height: 10),
            Text(
              tokens.text('strictNotice'),
              style: TextStyle(
                color: tokens.color('onSurfaceMuted'),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BuildRow extends StatelessWidget {
  const _BuildRow({
    required this.platform,
    required this.what,
    required this.status,
    required this.built,
  });

  final String platform;
  final String what;
  final String status;
  final bool built;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: UnplugCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    platform,
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                UnplugPill(
                  label: status,
                  background: built ? AppColors.mint : AppColors.coralLight,
                  foreground:
                      built ? AppColors.deepTeal : const Color(0xFF8C3A26),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              what,
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
