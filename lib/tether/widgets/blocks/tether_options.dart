import 'package:flutter/material.dart';

import '../../data/design_bundle.dart';
import '../../state/tether_scope.dart';
import '../../theme/tether_tokens.dart';

/// A single-select list. `.opt` / `.opt.on` / `.dot`.
///
/// Deliberately not wrapped in a card — the prototype emits these as bare
/// rows, so the options are the only thing on that stretch of screen. "Cut
/// back, or step away?" is the decision the whole plan hangs on, and the
/// design gives it nothing to compete with.
///
/// There is no way to clear a choice once made. That matches the prototype,
/// and it matches the screens: every options block in the shipped content
/// either arrives with a selection or offers a "prefer not to answer" row,
/// which is a better way to decline than an empty state nobody can find
/// their way back to.
class TetherOptions extends StatelessWidget {
  const TetherOptions({
    required this.block,
    required this.index,
    required this.areaId,
    required this.screenId,
    super.key,
  });

  final OptionsBlock block;
  final int index;
  final String areaId;
  final String screenId;

  @override
  Widget build(BuildContext context) {
    final session = TetherScope.of(context);

    // -1 means the content file selected nothing, which several blocks do.
    final initial = block.items.indexWhere((option) => option.selected);
    final chosen = session.optionSelection(areaId, screenId, index, initial);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < block.items.length; i++)
          _Option(
            option: block.items[i],
            selected: i == chosen,
            position: i + 1,
            total: block.items.length,
            onTap: () => session.chooseOption(areaId, screenId, index, i),
          ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.option,
    required this.selected,
    required this.position,
    required this.total,
    required this.onTap,
  });

  final ContentOption option;
  final bool selected;
  final int position;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        selected: selected,
        label: '${option.title}. Option $position of $total',
        hint: option.body,
        child: ExcludeSemantics(
          child: Material(
            color: selected ? TetherColors.mintPale : TetherColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: TetherRadius.optionAll,
              side: BorderSide(
                color: selected ? TetherColors.coral : TetherColors.line,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: _Dot(selected: selected),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(option.title, style: TetherText.cardTitle),
                          if (option.body case final String text) ...[
                            const SizedBox(height: 3),
                            Text(text, style: TetherText.cardBody),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.dot` — a filled ink circle when chosen, a grey ring when not.
class _Dot extends StatelessWidget {
  const _Dot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? TetherColors.ink : Colors.transparent,
        border: Border.all(
          color: selected ? TetherColors.ink : TetherColors.optionDot,
          width: 1.5,
        ),
      ),
    );
  }
}
