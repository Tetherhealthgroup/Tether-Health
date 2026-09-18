import 'package:flutter/material.dart';

import '../../data/design_bundle.dart';
import '../../state/tether_scope.dart';
import '../../theme/tether_tokens.dart';
import 'tether_card.dart';

/// `.sl` — a 0-to-100 slider with three labels under it.
///
/// The middle label is the only one drawn in ink, because it is the only one
/// that describes where the handle actually is. The outer two are the ends of
/// the scale.
///
/// The labels are supplied by the content file and do not recompute as the
/// handle moves. That is the prototype's behaviour and it is kept on purpose:
/// the mid label reads "6 · Moderate" or "2h 30m · cuts 40%", which are
/// product-specific translations of a raw 0-100 value that only the content
/// author knows how to write. Inventing them here would mean this widget
/// guessing at clinical wording, which is exactly what it must not do. The
/// person's actual position is carried to the screen reader instead.
class TetherSlider extends StatelessWidget {
  const TetherSlider({
    required this.block,
    required this.index,
    required this.areaId,
    required this.screenId,
    super.key,
  });

  final SliderBlock block;
  final int index;
  final String areaId;
  final String screenId;

  @override
  Widget build(BuildContext context) {
    final session = TetherScope.of(context);
    final value = session.sliderValue(areaId, screenId, index, block.value);

    return TetherCardShell(
      tone: CardTone.plain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (block.title case final String text)
            Text(text, style: TetherText.cardTitle),
          if (block.body case final String text)
            Padding(
              padding: const EdgeInsets.only(top: 3, bottom: 8),
              child: Text(text, style: TetherText.cardBody),
            ),
          Semantics(
            slider: true,
            label: block.title ?? 'Rating',
            value: '${value.round()} out of 100',
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: TetherColors.coral,
                inactiveTrackColor: TetherColors.line,
                thumbColor: TetherColors.coral,
              ),
              child: Slider(
                value: value.clamp(0, 100),
                max: 100,
                // A hundred stops would make a screen reader unusable and
                // would not help a thumb either. Twenty is one step per half
                // point on the 0-10 scales these actually represent.
                divisions: 20,
                label: '${value.round()}',
                onChanged: (next) =>
                    session.setSlider(areaId, screenId, index, next),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(block.left, style: TetherText.mini),
              ),
              Expanded(
                child: Text(
                  block.mid,
                  textAlign: TextAlign.center,
                  style: TetherText.mini.copyWith(
                    fontWeight: FontWeight.w600,
                    color: TetherColors.ink,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  block.right,
                  textAlign: TextAlign.right,
                  style: TetherText.mini,
                ),
              ),
            ],
          ),
          if (block.foot case final String text)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(text, style: TetherText.cardBody),
            ),
        ],
      ),
    );
  }
}
