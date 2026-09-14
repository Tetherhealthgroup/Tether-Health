import 'package:flutter/material.dart';

/// The Tether shell design tokens, transcribed from the `:root` block and
/// component rules of `files/tether-prototype.html`.
///
/// The shell is built once and is identical in every area (`shell.json`), so
/// these tokens belong to the shell rather than to LookUp, even though the
/// prototype they came from renders only LookUp. Every program drawn from the
/// shared archetypes inherits them.
///
/// They are deliberately separate from [AppColors], which carries the
/// BreatheFree artwork palette. The two are close but not identical — the
/// artwork's ink is `#123C37`, the shell's is `#17352C` — and collapsing them
/// into one palette would silently redraw approved artwork the first time
/// somebody nudged a value. The prototype is the source of truth for the
/// native shell, the 1290 × 2796 PNGs are the source of truth for the approved
/// BreatheFree screens, and neither gets to edit the other.
abstract final class TetherColors {
  /// `--ink`. Body text, the dark card fill, and the phone bezel.
  static const ink = Color(0xFF17352C);

  /// `--inkSoft`. The second dark card fill, used when two sit adjacent.
  static const inkSoft = Color(0xFF23453A);

  /// `--cream`. The page behind every light screen.
  static const cream = Color(0xFFF5F2EC);

  /// `--card`. Plain card fill.
  static const card = Color(0xFFFFFFFF);

  /// `--mint`. The affirming card fill and the resting bar colour.
  static const mint = Color(0xFFD7E9DE);

  /// `--mintPale`. The quieter mint, used for notes rather than results.
  static const mintPale = Color(0xFFE9F2EC);

  /// `--coral`. Progress fill, selected-chip border, slider thumb.
  static const coral = Color(0xFFEE6F55);

  /// `--coralPale`. The fill behind a coral-toned card. Crisis cards use this:
  /// the tone marks urgency without the alarm of a saturated red.
  static const coralPale = Color(0xFFFCEBE5);

  /// `--lime`. The one high-contrast accent. Reserved for the timer ring, the
  /// metric track, and the intercept's "do something else" button.
  static const lime = Color(0xFFD4EC5A);

  /// `--muted`. Secondary text on a light background.
  static const muted = Color(0xFF6E8078);

  /// `--line`. Hairlines and unselected control borders.
  static const line = Color(0xFFE7E3DB);

  /// Secondary text on a dark card (`.cd.ink .cb`).
  static const mutedOnDark = Color(0xFF9FB8AC);

  /// Control borders on a dark screen (`.phone.dark .bar .c`).
  static const lineOnDark = Color(0xFF3A5B4E);

  /// The metric card's unfilled track (`.track`).
  static const trackOnDark = Color(0xFF2E5548);

  /// Footer text (`.ft`). Lighter than [muted] on purpose — a footer is a
  /// disclosure, not a line anybody is meant to read first.
  static const footer = Color(0xFF98A6A0);

  /// The hairline between rows inside a `rows` block (`.rw`).
  static const rowDivider = Color(0xFFF0ECE4);

  /// The unselected radio ring inside an `options` block (`.dot`).
  static const optionDot = Color(0xFFC9D3CD);
}

/// Type scale, transcribed one-for-one from the prototype's component rules.
///
/// Sizes are given in the prototype as CSS pixels. Flutter logical pixels are
/// the same unit at a 1.0 text scale, so the numbers carry across unchanged;
/// what does not carry across is the browser's default line-height rounding,
/// which is why every style here states its `height` explicitly.
abstract final class TetherText {
  /// `.bar .t` — the screen title in the top bar.
  static const barTitle = TextStyle(
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: TetherColors.ink,
  );

  /// `.bg` — the status pill beside the title.
  static const badge = TextStyle(
    fontSize: 10,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: TetherColors.ink,
  );

  /// `.hl` — the one headline per screen.
  static const headline = TextStyle(
    fontSize: 21,
    height: 1.22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: TetherColors.ink,
  );

  /// `.sub` — the line under the headline.
  static const sub = TextStyle(
    fontSize: 13,
    height: 1.55,
    color: TetherColors.muted,
  );

  /// `.eb` — the uppercase eyebrow above a card title.
  static const eyebrow = TextStyle(
    fontSize: 10,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: TetherColors.muted,
  );

  /// `.ct` — a card's title.
  static const cardTitle = TextStyle(
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: TetherColors.ink,
  );

  /// `.cb` — a card's body.
  static const cardBody = TextStyle(
    fontSize: 13,
    height: 1.45,
    color: TetherColors.muted,
  );

  /// `.chip` — a selectable chip.
  static const chip = TextStyle(
    fontSize: 12.5,
    height: 1.3,
    color: TetherColors.ink,
  );

  /// `.st b` — the large number in a stat tile.
  static const statValue = TextStyle(
    fontSize: 19,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: TetherColors.ink,
  );

  /// `.st span` — the label under a stat tile's number.
  static const statLabel = TextStyle(
    fontSize: 11,
    height: 1.3,
    color: TetherColors.muted,
  );

  /// `.mt .v` — the primary metric's number.
  static const metricValue = TextStyle(
    fontSize: 30,
    height: 1.1,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  /// `.rw .k` — a row's uppercase key.
  static const rowKey = TextStyle(
    fontSize: 10,
    height: 1.4,
    letterSpacing: 0.8,
    color: TetherColors.muted,
  );

  /// `.rw .v` — a row's value.
  static const rowValue = TextStyle(
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: TetherColors.ink,
  );

  /// `.ring` — the countdown inside the timer ring.
  static const ring = TextStyle(
    fontSize: 34,
    height: 1.0,
    fontWeight: FontWeight.w700,
    color: TetherColors.ink,
  );

  /// `.tm .q` — the person's own words, shown under a running timer.
  static const timerQuote = TextStyle(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  /// `.mini` — the three labels under a slider.
  static const mini = TextStyle(
    fontSize: 11,
    height: 1.3,
    color: TetherColors.muted,
  );

  /// `.btn` — every action button.
  static const button = TextStyle(
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  /// `.btn.ghost` — a ghost button's label is a weight lighter than a primary.
  static const buttonGhost = TextStyle(
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w500,
    color: TetherColors.ink,
  );

  /// `.ft` — the disclosure line at the foot of a screen.
  static const footnote = TextStyle(
    fontSize: 11,
    height: 1.4,
    color: TetherColors.footer,
  );
}

/// Corner radii, transcribed from the prototype.
abstract final class TetherRadius {
  /// `.cd`, `.rows`, `.sl`, `.mt`, `.tm`, `.inp` — the standard block corner.
  static const block = Radius.circular(16);

  /// `.st` — stat tiles are a touch tighter than a full card.
  static const stat = Radius.circular(14);

  /// `.btn` — action buttons.
  static const button = Radius.circular(14);

  /// `.opt` — a selectable option row.
  static const option = Radius.circular(13);

  /// `.chip`, `.bg` — fully round.
  static const pill = Radius.circular(99);

  static const blockAll = BorderRadius.all(block);
  static const statAll = BorderRadius.all(stat);
  static const buttonAll = BorderRadius.all(button);
  static const optionAll = BorderRadius.all(option);
  static const pillAll = BorderRadius.all(pill);
}

/// Spacing, transcribed from the prototype.
abstract final class TetherSpace {
  /// `.phone` padding — the gutter between content and the screen edge.
  static const screenGutter = 14.0;

  /// `.cd` padding.
  static const cardPadding = EdgeInsets.all(14);

  /// `.cd` margin-bottom — the gap between two stacked blocks.
  static const blockGap = 10.0;

  /// `.chips` gap.
  static const chipGap = 7.0;

  /// `.stats` gap.
  static const statGap = 9.0;

  /// `.btn` margin-bottom.
  static const buttonGap = 8.0;

  /// `.btn` padding.
  static const buttonPadding = EdgeInsets.symmetric(vertical: 15);
}
