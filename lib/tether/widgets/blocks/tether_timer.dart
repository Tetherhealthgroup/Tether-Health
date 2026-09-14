import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/design_bundle.dart';
import '../../theme/tether_tokens.dart';

/// `.tm` — the countdown that is the intervention.
///
/// Two screens use it and they are the two the product exists for: the
/// ninety-second rescue, and the eight-second pause before a shielded app
/// opens. Both are the same block with a different number.
///
/// The countdown runs regardless of the platform's reduced-motion setting.
/// `reduced_motion_fallback` asks for the *animation* to degrade, not the
/// intervention: a person who has turned off motion effects has not asked to
/// be denied the ninety seconds. So the ring's colour transition is dropped
/// when motion is reduced and the number keeps ticking either way.
class TetherTimer extends StatefulWidget {
  const TetherTimer({required this.block, super.key});

  final TimerBlock block;

  @override
  State<TetherTimer> createState() => _TetherTimerState();
}

class _TetherTimerState extends State<TetherTimer> {
  late int _remaining = widget.block.seconds;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(TetherTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.seconds != widget.block.seconds) {
      _remaining = widget.block.seconds;
      _start();
    }
  }

  void _start() {
    _ticker?.cancel();
    if (_remaining <= 0) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // A route that has been pushed over is still mounted, and a
      // `Timer.periodic` is not a ticker — so without this check the rescue
      // screen keeps counting down, and rebuilding, from underneath whatever
      // is now on top of it. Ninety seconds of invisible frames is wasteful
      // anywhere; on a phone at 11pm it is battery.
      //
      // `TickerMode` is the obvious signal and the wrong one: Flutter only
      // disables it for a route that is *offstage*, not one that is merely
      // covered, so a covered rescue screen reads as enabled and keeps
      // counting. `isCurrent` is the question actually being asked.
      //
      // No route at all — a widget test pumping this block on its own — counts
      // as current, because there is nothing on top of it.
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;

      setState(() => _remaining = _remaining > 0 ? _remaining - 1 : 0);
      if (_remaining == 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: const BoxDecoration(
        color: TetherColors.ink,
        borderRadius: TetherRadius.blockAll,
      ),
      child: Column(
        children: [
          if (block.label.isNotEmpty)
            Text(
              block.label.toUpperCase(),
              style: TetherText.eyebrow.copyWith(
                color: TetherColors.mutedOnDark,
              ),
            ),
          const SizedBox(height: 12),
          Semantics(
            label: _remaining > 0
                ? '$_remaining seconds remaining'
                : 'Finished',
            child: ExcludeSemantics(
              child: Container(
                width: 118,
                height: 118,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: TetherColors.lime,
                  shape: BoxShape.circle,
                ),
                child: Text('$_remaining', style: TetherText.ring),
              ),
            ),
          ),
          if (block.quote case final String text) ...[
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TetherText.timerQuote,
            ),
          ],
        ],
      ),
    );
  }
}
