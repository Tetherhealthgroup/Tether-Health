import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../models/unplug_screen_spec.dart';
import 'unplug_scope.dart';

/// Where a screen sits in the module, and how to leave it.
///
/// Passed down from the host so no screen has to know its own index.
class UnplugNavigation {
  const UnplugNavigation({
    required this.spec,
    required this.position,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final UnplugScreenSpec spec;

  /// The screen's one-based position within the Unplug module.
  final int position;
  final int total;

  final VoidCallback onPrevious;
  final VoidCallback onNext;
}

/// The chrome every Unplug screen sits inside.
///
/// The 28 approved screens are full-bleed artwork and carry their own chrome.
/// The Unplug screens are native widgets, so they supply their own header,
/// scrolling body and footer navigation, which is also what makes the module
/// usable on a phone where there is no sidebar.
class UnplugPage extends StatelessWidget {
  const UnplugPage({
    required this.nav,
    required this.children,
    super.key,
  });

  final UnplugNavigation nav;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.cream,
      child: SafeArea(
        child: Column(
          children: [
            _UnplugHeader(spec: nav.spec),
            const _ModeBanner(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: children,
              ),
            ),
            _UnplugFooter(
              position: nav.position,
              total: nav.total,
              onPrevious: nav.onPrevious,
              onNext: nav.onNext,
            ),
          ],
        ),
      ),
    );
  }
}

/// States, on every screen, whether the numbers below mean anything.
///
/// A prototype that looks identical whether or not it is connected to a real
/// screen-time layer is a prototype that will eventually be demonstrated as if
/// it were connected. This strip is the cheapest defence against that.
class _ModeBanner extends StatelessWidget {
  const _ModeBanner();

  @override
  Widget build(BuildContext context) {
    final state = UnplugScope.of(context);
    final live = state.isLive;
    final failure = state.channelFailure;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      color: live && failure == null ? AppColors.mint : AppColors.coralLight,
      child: Row(
        children: [
          Icon(
            live && failure == null
                ? Icons.sensors_rounded
                : Icons.science_outlined,
            size: 15,
            color: live && failure == null
                ? AppColors.deepTeal
                : const Color(0xFF8C3A26),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              failure != null
                  ? 'Channel error — $failure'
                  : live
                      ? 'Live — reading this device'
                      : 'Simulated — no screen-time layer on this build',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: live && failure == null
                    ? AppColors.deepTeal
                    : const Color(0xFF8C3A26),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnplugHeader extends StatelessWidget {
  const _UnplugHeader({required this.spec});

  final UnplugScreenSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        color: AppColors.deepTeal,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  spec.letter,
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unplug v2.1 · ${spec.phase.label}',
                      style: const TextStyle(
                        color: Color(0xFFBFD5CD),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      spec.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _AddendumRef(reference: spec.addendumRef),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            spec.description,
            style: const TextStyle(
              color: Color(0xFFD3E5DE),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddendumRef extends StatelessWidget {
  const _AddendumRef({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Implements addendum $reference',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0x33D5EF75),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          reference,
          style: const TextStyle(
            color: AppColors.lime,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _UnplugFooter extends StatelessWidget {
  const _UnplugFooter({
    required this.position,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final int position;
  final int total;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onPrevious,
            tooltip: 'Previous screen',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              'Screen $position of $total',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: position == total ? null : onNext,
            tooltip: 'Next screen',
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}

/// A titled block of related content.
class UnplugSection extends StatelessWidget {
  const UnplugSection({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// A rounded surface that groups one idea.
class UnplugCard extends StatelessWidget {
  const UnplugCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.paper,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
  }
}

/// The tone of a [UnplugNote].
enum NoteTone { neutral, good, warning }

/// A short, sourced statement — a constraint, a consequence or a warning.
class UnplugNote extends StatelessWidget {
  const UnplugNote({
    required this.text,
    this.tone = NoteTone.neutral,
    this.icon,
    super.key,
  });

  final String text;
  final NoteTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, fallbackIcon) = switch (tone) {
      NoteTone.neutral => (
          AppColors.mint,
          AppColors.deepTeal,
          Icons.info_outline_rounded,
        ),
      NoteTone.good => (
          AppColors.mint,
          AppColors.deepTeal,
          Icons.check_circle_outline_rounded,
        ),
      NoteTone.warning => (
          AppColors.coralLight,
          const Color(0xFF8C3A26),
          Icons.error_outline_rounded,
        ),
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(13, 12, 14, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? fallbackIcon, size: 18, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact status label.
class UnplugPill extends StatelessWidget {
  const UnplugPill({
    required this.label,
    this.background = AppColors.mint,
    this.foreground = AppColors.deepTeal,
    super.key,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// A single-select row of choices.
class UnplugChoices<T> extends StatelessWidget {
  const UnplugChoices({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    super.key,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(labelOf(value)),
            selected: value == selected,
            showCheckmark: false,
            backgroundColor: AppColors.paper,
            selectedColor: AppColors.deepTeal,
            side: const BorderSide(color: AppColors.border),
            labelStyle: TextStyle(
              color: value == selected ? Colors.white : AppColors.deepTeal,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }
}

/// A label/value pair, used where a screen states a fact rather than offers a
/// control.
class UnplugFact extends StatelessWidget {
  const UnplugFact({
    required this.label,
    required this.value,
    this.emphasis = false,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: emphasis ? AppColors.deepTeal : AppColors.tealSecondary,
                fontSize: 13.5,
                height: 1.4,
                fontWeight: emphasis ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A horizontal magnitude bar, used by the baseline report.
class UnplugBar extends StatelessWidget {
  const UnplugBar({
    required this.label,
    required this.value,
    required this.fraction,
    this.dimmed = false,
    super.key,
  });

  final String label;
  final String value;

  /// 0–1, the share of the largest value in the same group.
  final double fraction;

  /// True when the bar is shown for completeness but is not a real measurement.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: dimmed ? AppColors.mutedTeal : AppColors.deepTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: dimmed ? AppColors.mutedTeal : AppColors.tealSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: 9,
              backgroundColor: AppColors.mint,
              valueColor: AlwaysStoppedAnimation<Color>(
                dimmed ? AppColors.mintStrong : AppColors.deepTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
