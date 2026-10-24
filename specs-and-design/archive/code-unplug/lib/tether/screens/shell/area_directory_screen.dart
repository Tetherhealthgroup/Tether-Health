/// SH2 — Health areas.
///
/// The screen that exists so the home screen does not have to. `shell.json`'s
/// `no_area_directory_on_home` rule keeps the catalogue off SH1; this is where
/// it lives, "reached on request, never on the home screen".
///
/// Its whole job is honesty about status. `areas.json` is a programme plan,
/// not a shipped catalogue: most of the eleven areas have no implementation at
/// all, and a row that reads like a product a person could start today would
/// be a lie told in a very expensive place. So every row states its status,
/// counts its service lines, and says plainly when there is nothing to join.
///
/// The counts in the status note are computed from the bundle rather than
/// written down, because a sentence that says "nine are a plan" goes stale the
/// first time somebody promotes an area and forgets this file.
library;

import 'package:flutter/material.dart';

import '../../data/design_bundle.dart';
import '../../state/tether_scope.dart';
import '../../theme/tether_tokens.dart';
import '../../widgets/tether_page.dart';
import 'shell_routes.dart';

/// The eleven areas, grouped by how far each has actually got.
///
/// Takes no arguments: the catalogue is the same for everybody, and filtering
/// it per person is the "turns a product into a menu" failure the shell rule
/// is guarding against.
class AreaDirectoryScreen extends StatelessWidget {
  const AreaDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = TetherScope.of(context);
    final bundle = session.bundle;
    final areas = bundle.areas;

    // Counted, never asserted. `areaRows` is specified as "required:11" and
    // the badge says so out loud, so a catalogue that lost an area is visible
    // rather than silent.
    final counts = <AreaStatus, int>{
      for (final status in AreaStatus.values)
        status: areas.where((area) => area.status == status).length,
    };
    final implemented = areas.where((area) => area.productId != null).length;

    return TetherPage(
      title: _shellName(bundle, 'SH2') ?? 'Health areas',
      badge: '${areas.length} areas',
      leading: LeadingControl.back,
      headline: 'What Tether covers, and what exists yet.',
      sub:
          'One area has code being written. The rest are a plan. Where a line sounds like something you could use now, it is not.',
      body: [
        // statusNote — "required". The authored sentence is kept exactly; the
        // arithmetic in front of it is generated so the two cannot disagree.
        _ShellCard(
          tone: CardTone.mintPale,
          // TODO(copy): status-note title.
          title: 'Where these stand',
          // TODO(copy): the two count sentences. Generated from `areas.json`,
          // so they are true by construction rather than by somebody
          // remembering to edit them. The third sentence is authored SH2 copy
          // and is reproduced exactly.
          body: '${_countSentence(counts, areas.length)} '
              'Areas with something built behind them: $implemented.\n\n'
              'Planned areas have no implementation. We will tell you when that changes, and not before.',
        ),

        // areaRows — "required:11", in catalogue order within each status
        // group. Grouping is by [AreaStatus] and the groups run in enum order,
        // which is most-advanced first: a reader scanning from the top reaches
        // the real thing before the plan.
        for (final status in AreaStatus.values)
          if (counts[status] != 0) ...[
            _GroupHeading(
              label: status.label,
              count: counts[status] ?? 0,
            ),
            for (final area in areas)
              if (area.status == status) _AreaRow(area: area),
          ],
      ],
      actions: [
        TetherActionButton(
          label: 'Back to your programs',
          kind: 'ghost',
          onPressed: () => _backToPrograms(context),
        ),
      ],
      footer: 'Nothing here is a diagnosis or a recommendation to enrol.',
    );
  }
}

/// One area, with everything a person needs to judge whether it is real.
///
/// Tappable only when the area has a product behind it. A row that opened SH3
/// for an area with no implementation would be a join flow that cannot end in
/// a join, and the honest version of that is not a dimmed button — it is a row
/// that says what it is.
class _AreaRow extends StatelessWidget {
  const _AreaRow({required this.area});

  final Area area;

  @override
  Widget build(BuildContext context) {
    final session = TetherScope.of(context);
    final joinable = area.productId != null;
    final product =
        area.productId == null ? null : session.bundle.products[area.productId];
    final enrolment = session.enrolment(area.id);
    final lines = area.serviceLines.length;

    return _ShellCard(
      tone: area.status == AreaStatus.inDevelopment
          ? CardTone.mint
          : CardTone.plain,
      eyebrow: area.status.label,
      title: area.name,
      body: area.scope.isEmpty
          ? null
          : '${area.scope} · $lines service ${lines == 1 ? 'line' : 'lines'}',
      onTap: joinable
          ? () =>
              Navigator.of(context).pushNamed(ShellRoutes.join, arguments: area)
          : null,
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: TetherSpace.chipGap,
          runSpacing: TetherSpace.chipGap,
          children: [
            if (enrolment.isJoined)
              // TODO(copy): already-joined marker on a directory row.
              const _Tag(label: 'You are in this', tone: CardTone.mint)
            else if (joinable)
              // "Read more", not "Join": SH3 is a reading screen and the
              // decision happens at the end of it.
              const _Tag(label: 'Read more', tone: CardTone.mint)
            else
              // TODO(copy): the not-joinable marker. Says the thing the
              // authored SH2 note says once, on every row it applies to.
              const _Tag(label: 'Nothing to join yet', tone: CardTone.plain),
            if (product != null)
              // TODO(copy): names the product that implements the area, so a
              // row and a program card can be matched up.
              _Tag(label: 'Built as ${product.name}', tone: CardTone.plain),
            if (area.hasClinicalThresholds)
              // `threshold_areas_separable`. Flagged on the row rather than
              // buried in SH3 because it is the reason this area may be
              // removed from a build entirely.
              // TODO(copy): threshold flag label.
              const _Tag(
                  label: 'Carries clinical thresholds', tone: CardTone.coral),
          ],
        ),
        if (area.url.isNotEmpty) ...[
          const SizedBox(height: 8),
          // Reference text, not a link. Opening a browser needs a dependency
          // this app does not have, and a tappable-looking URL that does
          // nothing is worse than a URL that never claimed to be tappable.
          Text(
            area.url,
            style: TetherText.footnote,
          ),
        ],
      ],
    );
  }
}

/// A status group's heading. Carries its own count so that the eleven rows are
/// verifiable by reading the screen.
class _GroupHeading extends StatelessWidget {
  const _GroupHeading({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          '${label.toUpperCase()} · $count',
          style: TetherText.eyebrow,
        ),
      ),
    );
  }
}

/// Builds the one generated sentence in the status note.
///
/// Only non-empty groups are named. A sentence that reports "0 in design" is
/// accurate and useless; a sentence that silently drops a group that has
/// filled up is neither.
String _countSentence(Map<AreaStatus, int> counts, int total) {
  final parts = <String>[
    for (final status in AreaStatus.values)
      if ((counts[status] ?? 0) > 0)
        '${counts[status]} ${status.label.toLowerCase()}',
  ];
  if (parts.isEmpty) return 'No areas are listed.';
  return '$total areas: ${parts.join(', ')}.';
}

String? _shellName(DesignBundle bundle, String id) {
  for (final screen in bundle.shell.screens) {
    if (screen.id == id) return screen.name;
  }
  return null;
}

/// Leaves the directory the way it was entered, and falls back to a named
/// route when there is no stack to pop — the directory is reachable from any
/// program, so it cannot assume it was pushed from SH1.
void _backToPrograms(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }
  navigator.pushReplacementNamed(ShellRoutes.programs);
}

// ---------------------------------------------------------------------------
// Local drawing
// ---------------------------------------------------------------------------

/// `.chip` — a non-interactive status tag.
///
/// Deliberately not a chip a person can press. Every fact on this screen is a
/// statement about the programme, and none of them is a control.
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.tone});

  final String label;
  final CardTone tone;

  @override
  Widget build(BuildContext context) {
    final background = switch (tone) {
      CardTone.mint => TetherColors.mint,
      CardTone.coral => TetherColors.coralPale,
      _ => TetherColors.cream,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: TetherRadius.pillAll,
        border: Border.all(color: TetherColors.line),
      ),
      child: Text(label, style: TetherText.chip),
    );
  }
}

/// `.cd` — the prototype's card. See the note in `programs_home_screen.dart`:
/// the shell screens draw their own cards because they carry live state rather
/// than authored blocks.
class _ShellCard extends StatelessWidget {
  const _ShellCard({
    this.tone = CardTone.plain,
    this.eyebrow,
    this.title,
    this.body,
    this.onTap,
    this.children = const <Widget>[],
  });

  final CardTone tone;
  final String? eyebrow;
  final String? title;
  final String? body;
  final VoidCallback? onTap;
  final List<Widget> children;

  Color get _fill => switch (tone) {
        CardTone.plain => TetherColors.card,
        CardTone.mint => TetherColors.mint,
        CardTone.mintPale => TetherColors.mintPale,
        CardTone.coral => TetherColors.coralPale,
        CardTone.ink => TetherColors.ink,
        CardTone.inkSoft => TetherColors.inkSoft,
      };

  @override
  Widget build(BuildContext context) {
    final dark = tone.isDark;
    final titleText = title;
    final bodyText = body;

    return Padding(
      padding: const EdgeInsets.only(bottom: TetherSpace.blockGap),
      child: Material(
        color: _fill,
        shape: RoundedRectangleBorder(
          borderRadius: TetherRadius.blockAll,
          side: tone == CardTone.plain
              ? const BorderSide(color: TetherColors.line)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: TetherSpace.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow case final String text) ...[
                  Text(
                    text.toUpperCase(),
                    style: TetherText.eyebrow.copyWith(
                      color:
                          dark ? TetherColors.mutedOnDark : TetherColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (titleText != null)
                  Text(
                    titleText,
                    style: TetherText.cardTitle.copyWith(
                      color: dark ? Colors.white : TetherColors.ink,
                    ),
                  ),
                if (bodyText != null) ...[
                  if (titleText != null) const SizedBox(height: 4),
                  Text(
                    bodyText,
                    style: TetherText.cardBody.copyWith(
                      color:
                          dark ? TetherColors.mutedOnDark : TetherColors.muted,
                    ),
                  ),
                ],
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
