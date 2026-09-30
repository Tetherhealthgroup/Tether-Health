import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/unplug_module_state.dart';
import '../widgets/unplug_kit.dart';
import '../widgets/unplug_scope.dart';

/// Screen D — the effort gate, module M5.
///
/// Addendum §2.1: effort gates run inside `ShieldAction`, which has a limited
/// execution window and no Flutter. That rules out anything long-running or
/// sensor-driven — a camera-based pushup counter is not realistic on iOS — and
/// leaves breathing, a typed commitment and a simple puzzle.
class UnplugScreenD extends StatefulWidget {
  const UnplugScreenD({required this.nav, super.key});

  final UnplugNavigation nav;

  @override
  State<UnplugScreenD> createState() => _UnplugScreenDState();
}

class _UnplugScreenDState extends State<UnplugScreenD> {
  static const _commitmentPhrase = 'I can come back to this later';

  bool _passed = false;

  Timer? _breathTimer;
  int _breathRemaining = 0;

  final _commitmentController = TextEditingController();

  (int, int) _sum = _newSum();
  final _answerController = TextEditingController();
  bool _answerWrong = false;

  static (int, int) _newSum() {
    final random = Random();
    return (random.nextInt(8) + 2, random.nextInt(8) + 2);
  }

  @override
  void initState() {
    super.initState();
    _commitmentController.addListener(_onCommitmentChanged);
  }

  @override
  void dispose() {
    _breathTimer?.cancel();
    _commitmentController
      ..removeListener(_onCommitmentChanged)
      ..dispose();
    _answerController.dispose();
    super.dispose();
  }

  /// Only meaningful while the commitment gate is showing; selecting another
  /// gate clears the field, so a stale match cannot carry over.
  void _onCommitmentChanged() {
    final matches = _commitmentController.text.trim().toLowerCase() ==
        _commitmentPhrase.toLowerCase();
    if (matches != _passed) setState(() => _passed = matches);
  }

  void _selectGate(UnplugModuleState state, EffortGateChoice gate) {
    _breathTimer?.cancel();
    state.selectGate(gate);
    setState(() {
      _passed = false;
      _breathRemaining = 0;
      _answerWrong = false;
      _commitmentController.clear();
      _answerController.clear();
      _sum = _newSum();
    });
  }

  void _startBreath(int seconds) {
    _breathTimer?.cancel();
    setState(() {
      _breathRemaining = seconds;
      _passed = false;
    });
    _breathTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _breathRemaining--;
        if (_breathRemaining <= 0) {
          _breathRemaining = 0;
          _passed = true;
          timer.cancel();
        }
      });
    });
  }

  void _checkAnswer() {
    final answer = int.tryParse(_answerController.text.trim());
    final correct = answer == _sum.$1 + _sum.$2;
    setState(() {
      _passed = correct;
      _answerWrong = !correct;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = UnplugScope.of(context);
    final breathSeconds = state.tokens?.breathSeconds;

    return UnplugPage(
      nav: widget.nav,
      children: [
        UnplugSection(
          title: 'Gate',
          child: UnplugChoices<EffortGateChoice>(
            values: state.availableGates,
            selected: state.gate,
            labelOf: (value) => value.label,
            onSelected: (value) => _selectGate(state, value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            state.gate.description,
            style: const TextStyle(
              color: AppColors.tealSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ),
        UnplugSection(
          title: 'Try it',
          child: switch (state.gate) {
            EffortGateChoice.breath => _BreathGate(
                seconds: breathSeconds,
                remaining: _breathRemaining,
                running: _breathTimer?.isActive ?? false,
                passed: _passed,
                onStart: breathSeconds == null
                    ? null
                    : () => _startBreath(breathSeconds),
              ),
            EffortGateChoice.commitment => _CommitmentGate(
                phrase: _commitmentPhrase,
                controller: _commitmentController,
                passed: _passed,
              ),
            EffortGateChoice.puzzle => _PuzzleGate(
                sum: _sum,
                controller: _answerController,
                wrong: _answerWrong,
                passed: _passed,
                onCheck: _checkAnswer,
              ),
          },
        ),
        if (_passed)
          const UnplugNote(
            tone: NoteTone.good,
            text: 'Gate cleared. The shield lifts for the length of the pass '
                'the tier allows, then reapplies without asking again.',
          ),
        const UnplugNote(
          text: 'All three gates run inside ShieldAction, which has a limited '
              'execution window and cannot run Flutter. Anything sensor-driven '
              'or long-running — a camera-based pushup counter, for instance — '
              'is not realistic on iOS.',
        ),
        if (state.childLockdownActive)
          const UnplugNote(
            text: 'The typed commitment is not offered on a child profile: a '
                'sentence someone types is a free-text field, whatever it is '
                'called (§3.2).',
          ),
        if (breathSeconds == null)
          const UnplugNote(
            tone: NoteTone.warning,
            text: 'The breath length comes from the shared intercept token '
                'file, which has not loaded. Screen C reports why.',
          ),
      ],
    );
  }
}

class _BreathGate extends StatelessWidget {
  const _BreathGate({
    required this.seconds,
    required this.remaining,
    required this.running,
    required this.passed,
    required this.onStart,
  });

  final int? seconds;
  final int remaining;
  final bool running;
  final bool passed;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final total = seconds ?? 0;
    final progress = total == 0 ? 0.0 : (total - remaining) / total;

    return UnplugCard(
      child: Column(
        children: [
          SizedBox(
            width: 128,
            height: 128,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 128,
                  height: 128,
                  child: CircularProgressIndicator(
                    value: running || passed ? progress : 0,
                    strokeWidth: 10,
                    backgroundColor: AppColors.mint,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.deepTeal,
                    ),
                  ),
                ),
                Text(
                  passed ? 'Done' : (running ? '$remaining' : '${total}s'),
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: running ? null : onStart,
              child: Text(passed ? 'Breathe again' : 'Start'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommitmentGate extends StatelessWidget {
  const _CommitmentGate({
    required this.phrase,
    required this.controller,
    required this.passed,
  });

  final String phrase;
  final TextEditingController controller;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    return UnplugCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“$phrase”',
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Type it out',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: passed
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.deepTeal,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _PuzzleGate extends StatelessWidget {
  const _PuzzleGate({
    required this.sum,
    required this.controller,
    required this.wrong,
    required this.passed,
    required this.onCheck,
  });

  final (int, int) sum;
  final TextEditingController controller;
  final bool wrong;
  final bool passed;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return UnplugCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${sum.$1} + ${sum.$2}',
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Answer',
              border: const OutlineInputBorder(),
              isDense: true,
              errorText: wrong ? 'Not quite. Try again.' : null,
              suffixIcon: passed
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.deepTeal,
                    )
                  : null,
            ),
            onSubmitted: (_) => onCheck(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: onCheck,
              child: const Text('Check'),
            ),
          ),
        ],
      ),
    );
  }
}
