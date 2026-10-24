import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/unplug_screen_spec.dart';
import '../widgets/unplug_kit.dart';
import 'unplug_screen_a.dart';
import 'unplug_screen_b.dart';
import 'unplug_screen_c.dart';
import 'unplug_screen_d.dart';
import 'unplug_screen_e.dart';
import 'unplug_screen_f.dart';
import 'unplug_screen_g.dart';
import 'unplug_screen_h.dart';
import 'unplug_screen_i.dart';
import 'unplug_screen_j.dart';
import 'unplug_screen_k.dart';
import 'unplug_screen_l.dart';

/// Renders one Unplug screen by letter.
///
/// The 28 approved screens are bitmaps with interaction rectangles laid over
/// them. These twelve are native widgets, so the host resolves a letter to a
/// widget rather than to an asset path.
///
/// Unlike the approved viewport, this one does not bind a horizontal swipe:
/// these screens contain sliders and scrollable content, and the page footer
/// already carries explicit previous and next controls. The keyboard shortcuts
/// stay, because the desktop review shell relies on them.
class UnplugScreenHost extends StatelessWidget {
  const UnplugScreenHost({
    required this.spec,
    required this.position,
    required this.total,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectLetter,
    super.key,
  });

  final UnplugScreenSpec spec;

  /// The screen's one-based position within the Unplug module.
  final int position;
  final int total;

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  /// Jumps to another Unplug screen by letter.
  final ValueChanged<String> onSelectLetter;

  @override
  Widget build(BuildContext context) {
    final nav = UnplugNavigation(
      spec: spec,
      position: position,
      total: total,
      onPrevious: onPrevious,
      onNext: onNext,
    );
    void openEffortGate() => onSelectLetter('D');

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft): onPrevious,
        const SingleActivator(LogicalKeyboardKey.arrowRight): onNext,
        const SingleActivator(LogicalKeyboardKey.pageUp): onPrevious,
        const SingleActivator(LogicalKeyboardKey.pageDown): onNext,
      },
      child: Focus(
        child: Semantics(
          label: 'Unplug screen ${spec.letter} of $total: ${spec.title}',
          container: true,
          child: switch (spec.letter) {
            'A' => UnplugScreenA(nav: nav),
            'B' => UnplugScreenB(nav: nav),
            'C' => UnplugScreenC(nav: nav, onOpenEffortGate: openEffortGate),
            'D' => UnplugScreenD(nav: nav),
            'E' => UnplugScreenE(nav: nav),
            'F' => UnplugScreenF(nav: nav),
            'G' => UnplugScreenG(nav: nav),
            'H' => UnplugScreenH(nav: nav, onOpenEffortGate: openEffortGate),
            'I' => UnplugScreenI(nav: nav),
            'J' => UnplugScreenJ(nav: nav),
            'K' => UnplugScreenK(nav: nav),
            'L' => UnplugScreenL(nav: nav),
            _ => throw ArgumentError.value(
                spec.letter,
                'letter',
                'No Unplug screen is registered for this letter.',
              ),
          },
        ),
      ),
    );
  }
}
