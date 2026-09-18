import 'package:flutter/material.dart';

import '../../data/design_bundle.dart';
import '../../theme/tether_tokens.dart';
import 'tether_card.dart';

/// `.stats` — two figures side by side, equal width.
class TetherStats extends StatelessWidget {
  const TetherStats({required this.block, super.key});

  final StatsBlock block;

  @override
  Widget build(BuildContext context) {
    if (block.items.isEmpty) return const SizedBox.shrink();

    // `.stats` is a flex row, so its tiles are the same height whatever their
    // labels wrap to. Reproducing that needs IntrinsicHeight: a bare
    // `CrossAxisAlignment.stretch` asks for infinite height inside the
    // scrolling body these always sit in, which throws rather than degrading.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < block.items.length; i++) ...[
            if (i > 0) const SizedBox(width: TetherSpace.statGap),
            Expanded(
              child: Semantics(
                label: '${block.items[i].$2}: ${block.items[i].$1}',
                child: ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: TetherColors.card,
                      borderRadius: TetherRadius.statAll,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(block.items[i].$1, style: TetherText.statValue),
                        Text(block.items[i].$2, style: TetherText.statLabel),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.mt` — the one dark card carrying a screen's primary number.
///
/// Value and unit share a baseline because the number alone is meaningless:
/// "94" is not a fact, "94 of 150 minutes" is. The prototype puts them in the
/// same line for the same reason.
class TetherMetric extends StatelessWidget {
  const TetherMetric({required this.block, super.key});

  final MetricBlock block;

  @override
  Widget build(BuildContext context) {
    final label = [
      if (block.eyebrow case final String text) text,
      block.value,
      if (block.unit case final String text) text,
      if (block.foot case final String text) text,
    ].join('. ');

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: TetherSpace.cardPadding,
          decoration: const BoxDecoration(
            color: TetherColors.ink,
            borderRadius: TetherRadius.blockAll,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (block.eyebrow case final String text)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    text.toUpperCase(),
                    style: TetherText.eyebrow.copyWith(
                      color: TetherColors.mutedOnDark,
                    ),
                  ),
                ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 6,
                children: [
                  Text(block.value, style: TetherText.metricValue),
                  if (block.unit case final String text)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        text,
                        style: TetherText.cardBody.copyWith(
                          color: TetherColors.mutedOnDark,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _Track(percent: block.percent),
              if (block.foot case final String text)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    text,
                    style: TetherText.cardBody.copyWith(
                      color: TetherColors.mutedOnDark,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.track` — lime on deep teal, 5px.
class _Track extends StatelessWidget {
  const _Track({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(3)),
      child: LinearProgressIndicator(
        value: (percent / 100).clamp(0.0, 1.0),
        minHeight: 5,
        backgroundColor: TetherColors.trackOnDark,
        valueColor: const AlwaysStoppedAnimation(TetherColors.lime),
      ),
    );
  }
}

/// `.bars` — a week at a glance.
///
/// A zero is a day that has not happened yet, not a day with no usage. The
/// prototype draws it at the same 18% floor as a real low day but leaves it
/// mint instead of colouring it coral, and that distinction is the only thing
/// telling somebody on day three of a baseline week that the flat bars ahead
/// of them are not a judgement.
class TetherBars extends StatelessWidget {
  const TetherBars({required this.block, super.key});

  final BarsBlock block;

  static const _height = 56.0;
  static const _floor = 18.0;

  @override
  Widget build(BuildContext context) {
    if (block.values.isEmpty) return const SizedBox.shrink();

    final recorded = block.values.where((value) => value > 0).length;

    return Semantics(
      label: '$recorded of ${block.values.length} days recorded so far',
      child: ExcludeSemantics(
        child: SizedBox(
          height: _height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < block.values.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: FractionallySizedBox(
                    heightFactor:
                        (block.values[i].toDouble().clamp(_floor, 100)) / 100,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: block.values[i] > 0
                            ? TetherColors.coral
                            : TetherColors.mint,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(3)),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `.rows` — a card of key-and-value rows with hairlines between them.
class TetherRows extends StatelessWidget {
  const TetherRows({required this.block, super.key});

  final RowsBlock block;

  @override
  Widget build(BuildContext context) {
    if (block.items.isEmpty) return const SizedBox.shrink();

    return TetherCardShell(
      tone: CardTone.plain,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < block.items.length; i++)
            Semantics(
              label: '${block.items[i].$1}: ${block.items[i].$2}',
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    border: i == block.items.length - 1
                        ? null
                        : const Border(
                            bottom: BorderSide(color: TetherColors.rowDivider),
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.items[i].$1.toUpperCase(),
                        style: TetherText.rowKey,
                      ),
                      Text(block.items[i].$2, style: TetherText.rowValue),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
