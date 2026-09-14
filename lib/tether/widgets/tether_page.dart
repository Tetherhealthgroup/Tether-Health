import 'package:flutter/material.dart';

import '../data/design_bundle.dart';
import '../theme/tether_tokens.dart';

/// The chrome every screen in every program sits inside.
///
/// Transcribed from the `.phone` / `.bar` / `.scroll` / `.acts` structure in
/// `files/tether-prototype.html`. The prototype draws a 330 × 660 phone on a
/// desktop page; here the phone *is* the device, so the bezel and the fixed
/// size are dropped and everything inside it is kept.
///
/// The ordering is load-bearing. Actions sit below the scroll area rather than
/// at the end of it, so the primary action is reachable one-handed without
/// scrolling — the rescue flow was designed for somebody in bed at 11pm, and a
/// button that has scrolled off the bottom is a button that does not exist.
class TetherPage extends StatelessWidget {
  const TetherPage({
    required this.title,
    required this.body,
    this.badge,
    this.progress,
    this.leading = LeadingControl.close,
    this.dark = false,
    this.headline,
    this.sub,
    this.actions = const <Widget>[],
    this.footer,
    this.onLeading,
    super.key,
  });

  final String title;

  /// The blocks, already built.
  final List<Widget> body;

  /// The status pill beside the title. Null draws a spacer of the pill's
  /// minimum width, so titles stay centred whether or not a screen has one.
  final String? badge;

  /// The progress hairline, 0 to 100. Null draws no hairline.
  final double? progress;

  final LeadingControl leading;

  /// Draw on ink rather than cream. Only the intercept uses it.
  final bool dark;

  final String? headline;
  final String? sub;

  /// Buttons, in order. Build them with [TetherActionButton].
  final List<Widget> actions;

  /// The disclosure line under the buttons.
  final String? footer;

  /// What the leading control does. Defaults to popping the route.
  final VoidCallback? onLeading;

  @override
  Widget build(BuildContext context) {
    final background = dark ? TetherColors.ink : TetherColors.cream;
    final onBackground = dark ? Colors.white : TetherColors.ink;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TetherSpace.screenGutter,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              _TopBar(
                title: title,
                badge: badge,
                leading: leading,
                dark: dark,
                onLeading: onLeading ?? () => Navigator.of(context).maybePop(),
              ),
              if (progress != null) ...[
                const SizedBox(height: 10),
                _ProgressHairline(percent: progress!),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 4),
                  children: [
                    if (headline case final String text) ...[
                      Text(
                        text,
                        style: TetherText.headline.copyWith(color: onBackground),
                      ),
                      const SizedBox(height: 5),
                    ],
                    if (sub case final String text) ...[
                      Text(
                        text,
                        style: TetherText.sub.copyWith(
                          color: dark ? Colors.white : TetherColors.muted,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    ...body,
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...actions,
              if (footer case final String text) ...[
                const SizedBox(height: 8),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TetherText.footnote,
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.bar` — leading control, centred title, trailing status pill.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.badge,
    required this.leading,
    required this.dark,
    required this.onLeading,
  });

  final String title;
  final String? badge;
  final LeadingControl leading;
  final bool dark;
  final VoidCallback onLeading;

  /// `.bar .c` is 34px square; `.bg` has a 58px minimum width. Both are
  /// reserved even when empty so the title stays put between screens.
  static const _controlSize = 34.0;
  static const _badgeMinWidth = 58.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading == LeadingControl.none)
          const SizedBox(width: _controlSize, height: _controlSize)
        else
          _RoundControl(
            icon: leading == LeadingControl.back
                ? Icons.arrow_back
                : Icons.close,
            semanticLabel: leading == LeadingControl.back ? 'Back' : 'Close',
            dark: dark,
            onPressed: onLeading,
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TetherText.barTitle.copyWith(
              color: dark ? Colors.white : TetherColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (badge case final String text)
          _Badge(text: text)
        else
          const SizedBox(width: _badgeMinWidth),
      ],
    );
  }
}

/// `.bar .c` — a circular control. White on cream, outlined on ink.
class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.semanticLabel,
    required this.dark,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final bool dark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _TopBar._controlSize,
      height: _TopBar._controlSize,
      child: Material(
        color: dark ? Colors.transparent : TetherColors.card,
        shape: CircleBorder(
          side: dark
              ? const BorderSide(color: TetherColors.lineOnDark)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          padding: EdgeInsets.zero,
          iconSize: 17,
          tooltip: semanticLabel,
          color: dark ? Colors.white : TetherColors.ink,
          onPressed: onPressed,
          icon: Icon(icon, semanticLabel: semanticLabel),
        ),
      ),
    );
  }
}

/// `.bg` — the uppercase status pill.
class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: _TopBar._badgeMinWidth),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: TetherColors.mint,
        borderRadius: TetherRadius.pillAll,
      ),
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: TetherText.badge,
      ),
    );
  }
}

/// `.pr` — the 3px progress hairline.
class _ProgressHairline extends StatelessWidget {
  const _ProgressHairline({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Progress',
      value: '${percent.round()} percent',
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(2)),
        child: LinearProgressIndicator(
          value: (percent / 100).clamp(0.0, 1.0),
          minHeight: 3,
          backgroundColor: TetherColors.line,
          valueColor: const AlwaysStoppedAnimation(TetherColors.coral),
        ),
      ),
    );
  }
}

/// `.btn` — a full-width action button in one of three kinds.
///
/// Three kinds exist and no more. The archetypes only ever declare `primary`
/// and `ghost`; `lime` appears exactly once in the shipped content, on the
/// intercept's "do something else instead", and its job is to be the one
/// button in the product that does not look like the others.
class TetherActionButton extends StatelessWidget {
  const TetherActionButton({
    required this.label,
    required this.onPressed,
    this.kind = 'primary',
    this.dark = false,
    super.key,
  });

  final String label;

  /// Null disables the button. Used where an action points at a screen that
  /// does not exist yet: a visibly dead button is better than one that
  /// silently does nothing.
  final VoidCallback? onPressed;

  /// `primary`, `ghost` or `lime`.
  final String kind;

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final isGhost = kind == 'ghost';
    final isLime = kind == 'lime';

    final background = switch (kind) {
      'ghost' => dark ? Colors.transparent : TetherColors.card,
      'lime' => TetherColors.lime,
      _ => TetherColors.ink,
    };
    final foreground = switch (kind) {
      'ghost' => dark ? Colors.white : TetherColors.ink,
      'lime' => TetherColors.ink,
      _ => Colors.white,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: TetherSpace.buttonGap),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: TetherColors.line,
            disabledForegroundColor: TetherColors.muted,
            elevation: 0,
            padding: TetherSpace.buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: TetherRadius.buttonAll,
              side: isGhost
                  ? BorderSide(
                      color:
                          dark ? TetherColors.lineOnDark : TetherColors.line,
                    )
                  : BorderSide.none,
            ),
            textStyle: isGhost || isLime
                ? TetherText.buttonGhost.copyWith(
                    fontWeight: isLime ? FontWeight.w600 : FontWeight.w500,
                  )
                : TetherText.button,
          ),
          child: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
