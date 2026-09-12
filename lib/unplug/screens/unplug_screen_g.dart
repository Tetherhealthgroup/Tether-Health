import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/unplug_module_state.dart';
import '../widgets/unplug_kit.dart';
import '../widgets/unplug_scope.dart';

/// Screen G — a focus session, over the channel contract in addendum §2.3.
///
/// Everything on this screen is Dart. `startSession(duration, scope, strict)`
/// and `endSession(overrideReason?)` are the only two calls that cross into
/// native code; the tier logic that decides whether a strict session may end
/// stays on this side of the boundary on purpose.
class UnplugScreenG extends StatefulWidget {
  const UnplugScreenG({required this.nav, super.key});

  final UnplugNavigation nav;

  @override
  State<UnplugScreenG> createState() => _UnplugScreenGState();
}

class _UnplugScreenGState extends State<UnplugScreenG> {
  static const _durations = <Duration>[
    Duration(minutes: 15),
    Duration(minutes: 25),
    Duration(minutes: 45),
    Duration(minutes: 90),
  ];

  Duration _duration = _durations[1];
  SessionScope _scope = SessionScope.selectedApps;
  bool _strict = false;

  Future<void> _end(UnplugModuleState state) async {
    final session = state.session;
    if (session == null) return;

    if (!session.strict || session.isCompleteAt(DateTime.now())) {
      state.endSession();
      return;
    }

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _StrictEndDialog(),
    );
    if (reason == null) return;
    state.endSession(reason: reason);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Session ended early. Logged: “$reason”')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = UnplugScope.of(context);
    final session = state.session;

    return UnplugPage(
      nav: widget.nav,
      children: [
        if (session == null) ...[
          UnplugSection(
            title: 'Duration',
            child: UnplugChoices<Duration>(
              values: _durations,
              selected: _duration,
              labelOf: (value) => '${value.inMinutes} min',
              onSelected: (value) => setState(() => _duration = value),
            ),
          ),
          UnplugSection(
            title: 'Scope',
            child: UnplugChoices<SessionScope>(
              values: SessionScope.values,
              selected: _scope,
              labelOf: (value) => value.label,
              onSelected: (value) => setState(() => _scope = value),
            ),
          ),
          UnplugSection(
            title: 'Strict',
            child: UnplugCard(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'A strict session cannot be ended without a reason, and '
                      'the reason is recorded.',
                      style: TextStyle(
                        color: AppColors.tealSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                  Switch(
                    value: _strict,
                    onChanged: (value) => setState(() => _strict = value),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => state.startSession(
                  duration: _duration,
                  scope: _scope,
                  strict: _strict,
                ),
                child: const Text('Start session'),
              ),
            ),
          ),
        ] else
          _RunningSession(session: session, onEnd: () => _end(state)),
        const UnplugSection(
          title: 'The channel surface',
          child: UnplugCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ContractLine('applyShield(moduleConfig, appSelection)'),
                _ContractLine('liftShield(reason)'),
                _ContractLine('startSession(duration, scope, strict)'),
                _ContractLine('endSession(overrideReason?)'),
                _ContractLine('setThresholds(minutes[], opens[])'),
                _ContractLine('requestAuthorization(mode)'),
                _ContractLine('onThresholdCrossed →'),
                _ContractLine('onShieldShown →'),
                _ContractLine('onShieldDismissed →'),
                _ContractLine('onOverrideUsed →'),
              ],
            ),
          ),
        ),
        const UnplugNote(
          text: 'Pigeon generates this contract for all three sides, so a '
              'change to the signature breaks the build rather than the app. '
              'Keeping the surface this small is what stops tier logic leaking '
              'into native code.',
        ),
      ],
    );
  }
}

class _RunningSession extends StatelessWidget {
  const _RunningSession({required this.session, required this.onEnd});

  final FocusSession session;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remaining = session.remainingAt(now);
    final elapsed = session.duration - remaining;
    final progress = session.duration.inSeconds == 0
        ? 1.0
        : elapsed.inSeconds / session.duration.inSeconds;
    final complete = session.isCompleteAt(now);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: UnplugCard(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Column(
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0, 1),
                      strokeWidth: 12,
                      backgroundColor: AppColors.mint,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.deepTeal,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _clock(remaining),
                        style: const TextStyle(
                          color: AppColors.deepTeal,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        complete ? 'complete' : 'remaining',
                        style: const TextStyle(
                          color: AppColors.mutedTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            UnplugFact(label: 'Scope', value: session.scope.label),
            UnplugFact(
              label: 'Strict',
              value: session.strict
                  ? 'On — ending early needs a reason'
                  : 'Off — can be ended at any time',
              emphasis: session.strict,
            ),
            UnplugFact(
              label: 'Started',
              value: _clockOfDay(session.startedAt),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onEnd,
                child: Text(complete ? 'Finish' : 'End session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _clock(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static String _clockOfDay(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

class _StrictEndDialog extends StatefulWidget {
  const _StrictEndDialog();

  @override
  State<_StrictEndDialog> createState() => _StrictEndDialogState();
}

class _StrictEndDialogState extends State<_StrictEndDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('End a strict session?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Give a reason. It is recorded against the session, and it is the '
            'only thing that makes the log worth reading later.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep going'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('End session'),
        ),
      ],
    );
  }
}

class _ContractLine extends StatelessWidget {
  const _ContractLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.deepTeal,
          fontFamily: 'monospace',
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
    );
  }
}
