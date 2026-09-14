import 'package:flutter/material.dart';

import '../../data/design_bundle.dart';
import '../../state/tether_scope.dart';
import '../../theme/tether_tokens.dart';
import '../call_affordance.dart';

/// The container every block sits in: `.cd`, in one of six tones.
///
/// Tone is not decoration. Mint is the affirming result, coral is the card
/// that wants attention without alarming anyone, and ink is the one card on a
/// screen that carries its primary number or its recommended action. Two ink
/// cards on one screen would be two competing primary actions, which is a
/// structural fault the bundle's cold-read test looks for.
class TetherCardShell extends StatelessWidget {
  const TetherCardShell({
    required this.tone,
    required this.child,
    this.onTap,
    this.padding = TetherSpace.cardPadding,
    super.key,
  });

  final CardTone tone;
  final Widget child;

  /// Set when the card navigates. `.cd.tap` in the prototype.
  final VoidCallback? onTap;

  final EdgeInsets padding;

  static Color background(CardTone tone) => switch (tone) {
        CardTone.plain => TetherColors.card,
        CardTone.mint => TetherColors.mint,
        CardTone.mintPale => TetherColors.mintPale,
        // `.cd.coral` uses the pale fill, not the saturated coral. The
        // saturated one is reserved for progress and selection.
        CardTone.coral => TetherColors.coralPale,
        CardTone.ink => TetherColors.ink,
        CardTone.inkSoft => TetherColors.inkSoft,
      };

  /// Title colour for a tone.
  static Color foreground(CardTone tone) =>
      tone.isDark ? Colors.white : TetherColors.ink;

  /// Body and eyebrow colour for a tone.
  static Color secondary(CardTone tone) =>
      tone.isDark ? TetherColors.mutedOnDark : TetherColors.muted;

  @override
  Widget build(BuildContext context) {
    final decorated = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: background(tone),
        borderRadius: TetherRadius.blockAll,
      ),
      child: child,
    );

    if (onTap == null) return decorated;

    return Material(
      color: Colors.transparent,
      borderRadius: TetherRadius.blockAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: TetherRadius.blockAll,
        child: decorated,
      ),
    );
  }
}

/// A row of chips, multi-select. `.chips` / `.chip` / `.chip.on`.
///
/// Multi-select is the right default for what these actually ask: "anything
/// affecting you today?" takes more than one answer, and forcing a single
/// choice there would quietly make the data wrong.
class TetherChipRow extends StatelessWidget {
  const TetherChipRow({
    required this.items,
    required this.initial,
    required this.index,
    required this.areaId,
    required this.screenId,
    this.onDark = false,
    super.key,
  });

  final List<String> items;

  /// The selection the content file ships with.
  final Set<int> initial;

  final int index;
  final String areaId;
  final String screenId;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final session = TetherScope.of(context);
    final selected = session.chipSelection(areaId, screenId, index, initial);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: TetherSpace.chipGap,
        runSpacing: TetherSpace.chipGap,
        children: [
          for (var i = 0; i < items.length; i++)
            _Chip(
              label: items[i],
              selected: selected.contains(i),
              onDark: onDark,
              onTap: () => session.toggleChip(areaId, screenId, index, i),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool onDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? TetherColors.mintPale
            : (onDark ? Colors.transparent : TetherColors.card),
        shape: RoundedRectangleBorder(
          borderRadius: TetherRadius.pillAll,
          side: BorderSide(
            color: selected
                ? TetherColors.coral
                : (onDark ? TetherColors.lineOnDark : TetherColors.line),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            // A chip is a target for a thumb, one-handed, at 11pm. The
            // prototype's 8px padding gives about 33px of height in a browser;
            // 44 is the floor on a phone.
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: TetherText.chip.copyWith(
                    color: selected || !onDark
                        ? TetherColors.ink
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A `card` block: eyebrow, title, body, pill, chips — any combination.
class TetherCard extends StatelessWidget {
  const TetherCard({
    required this.block,
    required this.index,
    required this.areaId,
    required this.screenId,
    required this.onNavigate,
    this.dark = false,
    super.key,
  });

  final CardBlock block;
  final int index;
  final String areaId;
  final String screenId;
  final ValueChanged<String> onNavigate;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final tone = block.tone;
    final title = TetherCardShell.foreground(tone);
    final secondary = TetherCardShell.secondary(tone);
    final target = block.to;

    return TetherCardShell(
      tone: tone,
      onTap: target == null ? null : () => onNavigate(target),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (block.eyebrow case final String text) ...[
            Text(
              text.toUpperCase(),
              style: TetherText.eyebrow.copyWith(color: secondary),
            ),
            const SizedBox(height: 4),
          ],
          if (block.title case final String text) ...[
            Text(text, style: TetherText.cardTitle.copyWith(color: title)),
            const SizedBox(height: 3),
          ],
          if (block.body case final String text)
            Text(text, style: TetherText.cardBody.copyWith(color: secondary)),
          if (block.pill case final String text)
            _Pill(
              label: text,
              // Three different things wear the same word in the content file,
              // and drawing them identically is what made two of them lie.
              //
              // - On a card that navigates, the pill labels the destination.
              //   The card is the control; the pill is chip-styled because
              //   chip styling is how this design says "this leads somewhere".
              // - `Call 988` and `Call 911` are the only pills that name an
              //   action the app can actually perform. They get a real
              //   control, because a dead crisis-call button is the single
              //   worst defect available in a health product.
              // - Everything else — "Set it up", "Match my quiet hours" —
              //   describes something this build cannot do. Those are drawn
              //   as labels, not chips. Inventing a feature to justify the
              //   styling would be the wrong repair; removing the false
              //   affordance is the right one.
              kind: switch ((target, CallAffordance.numberIn(text))) {
                (final String _, _) => _PillKind.destination,
                (null, final String _) => _PillKind.call,
                _ => _PillKind.label,
              },
              onDark: tone.isDark || dark,
              onCall: () => CallAffordance.offer(
                context,
                name: block.title ?? 'this number',
                number: CallAffordance.numberIn(text) ?? text,
              ),
            ),
          TetherChipRow(
            items: block.chips,
            initial: block.selected,
            index: index,
            areaId: areaId,
            screenId: screenId,
            onDark: tone.isDark || dark,
          ),
        ],
      ),
    );
  }
}

/// What a card's `pill` actually is.
enum _PillKind {
  /// The card navigates. The pill names where.
  destination,

  /// The pill offers a phone number and is a control in its own right.
  call,

  /// The pill describes an action nothing in this build performs.
  label,
}

/// A card's `pill`.
///
/// The reference renderer draws every one of these as `.chip.on` — a selected
/// chip. That is right for the fifteen that sit on a card which navigates, and
/// wrong for the eight that do not: chip styling promises a control, and
/// pressing those eight did nothing at all. Two of them read "Call 988" and
/// "Call 911".
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.kind,
    required this.onDark,
    required this.onCall,
  });

  final String label;
  final _PillKind kind;
  final bool onDark;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: TetherColors.mintPale,
        borderRadius: TetherRadius.pillAll,
        border: Border.all(color: TetherColors.coral),
      ),
      child: Text(label, style: TetherText.chip),
    );

    final child = switch (kind) {
      // Decorative: the card around it already carries the tap and announces
      // it, so a screen reader reading this too would offer the same action
      // twice.
      _PillKind.destination => ExcludeSemantics(child: chip),

      _PillKind.call => Semantics(
          button: true,
          label: label,
          child: Material(
            color: Colors.transparent,
            borderRadius: TetherRadius.pillAll,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onCall,
              borderRadius: TetherRadius.pillAll,
              child: ConstrainedBox(
                // A crisis control, reached one-handed by somebody who is not
                // at their best. It gets a full-size target.
                constraints: const BoxConstraints(minHeight: 44),
                child: Center(widthFactor: 1, child: chip),
              ),
            ),
          ),
        ),

      // No border, no fill, no chip. It is a line of text describing what the
      // card is about, which is all it ever was.
      _PillKind.label => Text(
          label,
          style: TetherText.chip.copyWith(
            fontWeight: FontWeight.w600,
            color: onDark ? TetherColors.mutedOnDark : TetherColors.muted,
          ),
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }
}

/// A bare `chips` block, wrapped in a plain card as the prototype does.
class TetherChipsCard extends StatelessWidget {
  const TetherChipsCard({
    required this.block,
    required this.index,
    required this.areaId,
    required this.screenId,
    super.key,
  });

  final ChipsBlock block;
  final int index;
  final String areaId;
  final String screenId;

  @override
  Widget build(BuildContext context) {
    return TetherCardShell(
      tone: CardTone.plain,
      // The chip row supplies its own 10px top margin, which would read as
      // padding inside an otherwise empty card.
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: TetherChipRow(
        items: block.items,
        initial: block.selected,
        index: index,
        areaId: areaId,
        screenId: screenId,
      ),
    );
  }
}
