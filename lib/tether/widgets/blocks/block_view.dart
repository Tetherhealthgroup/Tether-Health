import 'package:flutter/material.dart';

import '../../data/design_bundle.dart';
import '../../theme/tether_tokens.dart';
import 'tether_card.dart';
import 'tether_figures.dart';
import 'tether_input.dart';
import 'tether_options.dart';
import 'tether_slider.dart';
import 'tether_timer.dart';

/// Draws one content block.
///
/// A port of the `block()` function in `tools/prototype.py`, which is the
/// reference renderer for this JSON. Where the two could differ they do not:
/// the bar heights, the pill-as-selected-chip, the bold middle slider label
/// and the "unknown `t` is a card" fallback are all copied rather than
/// reinvented, so a design reviewed in the browser prototype is the design
/// that ships.
class BlockView extends StatelessWidget {
  const BlockView({
    required this.block,
    required this.index,
    required this.areaId,
    required this.screenId,
    required this.onNavigate,
    this.dark = false,
    super.key,
  });

  final ContentBlock block;

  /// The block's position in its screen's list. Every answer the person gives
  /// is keyed by it, so it must be the index in the unfiltered list.
  final int index;

  /// The program this screen is being drawn inside.
  ///
  /// Carried alongside [screenId] and not derivable from it: two areas can
  /// share a product and therefore a whole screen list, so the id names the
  /// screen and only this names whose record the answer belongs in. See
  /// `TetherSession.answersFor`.
  final String areaId;

  final String screenId;

  /// Called with a screen id when the block is tapped through.
  final ValueChanged<String> onNavigate;

  /// The screen is drawn on ink rather than cream.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    // Every block carries its own bottom margin in the prototype
    // (`margin-bottom:10px` on each of `.cd`, `.rows`, `.sl`, `.mt`, `.tm`,
    // `.inp`, `.stats`, `.bars`). Applying it once here instead of in seven
    // widgets means a screen can never end up with a doubled or missing gap
    // depending on which block types it happens to use.
    return Padding(
      padding: const EdgeInsets.only(bottom: TetherSpace.blockGap),
      child: switch (block) {
        final CardBlock card => TetherCard(
            block: card,
            index: index,
            areaId: areaId,
            screenId: screenId,
            onNavigate: onNavigate,
            dark: dark,
          ),
        final ChipsBlock chips => TetherChipsCard(
            block: chips,
            index: index,
            areaId: areaId,
            screenId: screenId,
          ),
        final OptionsBlock options => TetherOptions(
            block: options,
            index: index,
            areaId: areaId,
            screenId: screenId,
          ),
        final StatsBlock stats => TetherStats(block: stats),
        final MetricBlock metric => TetherMetric(block: metric),
        final BarsBlock bars => TetherBars(block: bars),
        final RowsBlock rows => TetherRows(block: rows),
        final SliderBlock slider => TetherSlider(
            block: slider,
            index: index,
            areaId: areaId,
            screenId: screenId,
          ),
        final TimerBlock timer => TetherTimer(block: timer),
        final InputBlock input => TetherInput(
            block: input,
            index: index,
            areaId: areaId,
            screenId: screenId,
          ),
      },
    );
  }
}
