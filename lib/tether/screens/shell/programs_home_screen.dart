/// SH1 — Your programs.
///
/// The one screen in the shell that has to resist the strongest product
/// instinct there is: putting the catalogue on the home screen.
/// `shell.json`'s `no_area_directory_on_home` rule forbids it, and the reason
/// is not tidiness — "a directory leaks what a person is dealing with to
/// anyone who picks up the phone, and turns a product into a menu". So this
/// screen shows what is running and nothing else, and the eleven areas are one
/// deliberate tap away at [ShellRoutes.areas].
///
/// It is hand-built rather than rendered from `content.lookup.en.json` because
/// the authored copy describes one particular person — two active programs, a
/// paused Healthy weight, a hidden BreatheFree — and the screen has to be true
/// for the person holding the phone. Every card here is derived from
/// [TetherSession]; the authored sentences are reused verbatim wherever the
/// live state happens to match the shape they were written for.
library;

import 'package:flutter/material.dart';

import '../../data/design_bundle.dart';
import '../../state/tether_scope.dart';
import '../../state/tether_session.dart';
import '../../theme/tether_tokens.dart';
import '../../widgets/tether_page.dart';
import 'shell_routes.dart';

/// The host shell's home screen.
///
/// Takes no arguments on purpose. There is one home screen for the whole app,
/// not one per program — a per-program home would need a program to be
/// "current", and the moment something is current the other one is demoted.
class ProgramsHomeScreen extends StatelessWidget {
  const ProgramsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = TetherScope.of(context);
    final bundle = session.bundle;

    final visible = session.visiblePrograms;
    final hidden = session.activePrograms
        .where((enrolment) => enrolment.hidden)
        .toList(growable: false);
    final paused = session.pausedPrograms;
    final activeCount = session.activePrograms.length;
    final nothingJoined =
        activeCount == 0 && paused.isEmpty && hidden.isEmpty;

    // The ceiling is read from the bundle rather than written here, so that
    // editing `shell.json` edits the app. See [ShellSpec.maxActivePrograms].
    final ceiling = session.maxActivePrograms;
    final ceilingRule = bundle.shell.rule('two_active_max');

    return TetherPage(
      title: _shellName(bundle, 'SH1') ?? 'Your programs',
      badge: 'Private',
      // This is the root of the shell. Offering a back arrow with nothing
      // behind it is a control that lies about what it does.
      leading: Navigator.of(context).canPop()
          ? LeadingControl.back
          : LeadingControl.none,
      headline: nothingJoined
          // TODO(copy): zero-program headline. The authored SH1 copy assumes
          // two active programs and has nothing for an empty shell.
          ? 'Nothing running yet.'
          : 'Two at a time, at most.',
      sub: nothingJoined
          // TODO(copy): zero-program sub, written to carry the same ceiling
          // rule the authored sub carries.
          ? 'When you join a program it shows up here. Two at a time, at most — three concurrent changes is where most people stall.'
          : 'Three concurrent changes is where most people stall. A third needs a conversation, not a tap.',
      body: [
        if (nothingJoined)
          const _ShellCard(
            // TODO(copy): empty-state card title.
            title: 'You have not joined anything',
            // TODO(copy): empty-state card body. Deliberately does not name an
            // area, because naming one here would be the directory this screen
            // is forbidden from showing.
            body: 'Look at an area when you are ready, read what joining changes, and decide then. Nothing starts on its own.',
          ),

        // activeCards — "required:0-2". Zero is a legitimate state and is why
        // the slot spec starts at zero rather than one.
        // The first card is drawn on ink and the second on pale mint, exactly
        // as the authored SH1 copy pairs them: two dark cards side by side
        // read as a single slab rather than as two programs.
        for (var index = 0; index < visible.length; index++)
          _ProgramCard(
            enrolment: visible[index],
            tone: index == 0 ? CardTone.ink : CardTone.mintPale,
          ),

        if (activeCount == 1)
          const _ShellCard(
            tone: CardTone.mintPale,
            // TODO(copy): one-program card title.
            title: 'Room for one more',
            // TODO(copy): one-program card body. Second sentence echoes the
            // authored sub so the ceiling is stated the same way twice.
            body: 'You can add a second program whenever you want. A third needs a conversation, not a tap.',
          ),

        // pausedRows — "optional". A paused program is still joined: it does
        // not count against the ceiling and its history is kept, which is why
        // it is a row rather than a card that competes for attention.
        if (paused.isNotEmpty)
          _RowsCard(
            items: [
              for (final enrolment in paused)
                (
                  'Paused',
                  // TODO(copy): paused row value. Structure taken from the
                  // authored row "Healthy weight · resumes when you say so".
                  '${_displayName(session, enrolment.areaId)} · resumes when you say so',
                ),
            ],
          ),
        if (paused.isNotEmpty)
          for (final enrolment in paused)
            _ResumeRow(enrolment: enrolment, ceiling: ceiling),

        // `discreet_program`: hidden programs are running. They are simply not
        // on the home screen, and this note is the only trace of them here.
        if (hidden.isNotEmpty)
          _ShellCard(
            title: 'Hidden from your home screen',
            // TODO(copy): the sentence structure is authored; the names and
            // the plural are generated.
            body: '${_nameList(session, hidden)} ${hidden.length == 1 ? 'is' : 'are'} reachable only from here. Nothing shows on your lock screen.',
            children: [
              const SizedBox(height: 10),
              Wrap(
                spacing: TetherSpace.chipGap,
                runSpacing: TetherSpace.chipGap,
                children: [
                  for (final enrolment in hidden)
                    _InlineAction(
                      // TODO(copy): un-hide control label.
                      label: 'Show ${_displayName(session, enrolment.areaId)}',
                      onPressed: () =>
                          session.setHidden(enrolment.areaId, hidden: false),
                    ),
                ],
              ),
            ],
          ),

        // The rule itself, in the bundle's own words. It is on the screen
        // rather than in a help page because it is the constraint that shapes
        // everything above it, and a person who hits it deserves the reason.
        if (ceilingRule != null)
          _ShellCard(
            tone: CardTone.mintPale,
            // TODO(copy): eyebrow over the ceiling rule.
            eyebrow: 'The limit',
            title: ceilingRule.rule,
            body: ceilingRule.why,
          ),

        // The remaining shell screens, titled and described in `shell.json`'s
        // own words. They are rows here rather than a tab bar because the
        // record and the sharing matrix are things a person goes looking for,
        // not things they need in front of them every day.
        for (final entry in const <(String, String)>[
          ('SH4', ShellRoutes.record),
          ('SH5', ShellRoutes.sharing),
        ])
          if (_shellName(bundle, entry.$1) case final String name)
            _ShellCard(
              title: name,
              body: _shellPurpose(bundle, entry.$1),
              onTap: () => Navigator.of(context).pushNamed(entry.$2),
            ),
      ],
      actions: [
        // addAction — "required". One way to add another, never a list of
        // eleven.
        TetherActionButton(
          label: 'Look at another area',
          onPressed: () =>
              Navigator.of(context).pushNamed(ShellRoutes.areas),
        ),
        TetherActionButton(
          label: _shellName(session.bundle, 'SH6') ?? 'Get help now',
          kind: 'ghost',
          onPressed: () =>
              Navigator.of(context).pushNamed(ShellRoutes.crisis),
        ),
      ],
      footer: 'Each program shares separately. Nothing is pooled.',
    );
  }
}

/// One active, visible program.
///
/// The eyebrow counts in weeks because that is how the authored copy counts
/// ("Active · week 4"), and because a day counter makes a bad week look like a
/// failure. Where the session has no join date the week is simply omitted
/// rather than guessed at.
class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.enrolment, required this.tone});

  final Enrolment enrolment;
  final CardTone tone;

  @override
  Widget build(BuildContext context) {
    final session = TetherScope.of(context);
    final area = session.bundle.area(enrolment.areaId);
    final joinedOn = enrolment.joinedOn;
    final week = joinedOn == null
        ? null
        : DateTime.now().difference(joinedOn).inDays ~/ 7 + 1;

    return _ShellCard(
      tone: tone,
      eyebrow: week == null ? 'Active' : 'Active · week $week',
      title: _displayName(session, enrolment.areaId),
      body: area?.name,
      children: [
        const SizedBox(height: 10),
        Wrap(
          spacing: TetherSpace.chipGap,
          runSpacing: TetherSpace.chipGap,
          children: [
            _InlineAction(
              // TODO(copy): pause control label.
              label: 'Pause',
              dark: tone.isDark,
              onPressed: () => session.pause(enrolment.areaId),
            ),
            _InlineAction(
              // TODO(copy): hide control label. Names the rule it serves
              // rather than the mechanism.
              label: 'Hide from home',
              dark: tone.isDark,
              onPressed: () =>
                  session.setHidden(enrolment.areaId, hidden: true),
            ),
          ],
        ),
      ],
    );
  }
}

/// The control that brings a paused program back, and the honest reason it is
/// sometimes unavailable.
class _ResumeRow extends StatelessWidget {
  const _ResumeRow({required this.enrolment, required this.ceiling});

  final Enrolment enrolment;
  final int ceiling;

  @override
  Widget build(BuildContext context) {
    final session = TetherScope.of(context);
    final hasRoom = session.activePrograms.length < ceiling;
    final name = _displayName(session, enrolment.areaId);

    return Padding(
      padding: const EdgeInsets.only(bottom: TetherSpace.blockGap),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _InlineAction(
          // TODO(copy): resume control label, and the refusal that replaces it
          // when the ceiling is already full.
          label: hasRoom ? 'Resume $name' : 'No room to resume $name yet',
          onPressed: hasRoom ? () => session.resume(enrolment.areaId) : null,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Naming
// ---------------------------------------------------------------------------

/// What to call a program on screen.
///
/// A product name where one exists — the person joined BreatheFree, not
/// "Tobacco & nicotine" — and the area name where none does. The nine areas
/// without a product file still have to be nameable, because a paused or ended
/// enrolment outlives whatever built it.
String _displayName(TetherSession session, String areaId) {
  final product = session.bundle.productForArea(areaId);
  if (product != null) return product.name;
  return session.bundle.area(areaId)?.name ?? areaId;
}

String _nameList(TetherSession session, List<Enrolment> enrolments) {
  final names = [
    for (final enrolment in enrolments) _displayName(session, enrolment.areaId),
  ];
  if (names.length <= 1) return names.isEmpty ? '' : names.first;
  return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}

/// The name `shell.json` gives a screen, so that the shell's own vocabulary is
/// the one on screen rather than a second copy of it in Dart.
String? _shellName(DesignBundle bundle, String id) {
  for (final screen in bundle.shell.screens) {
    if (screen.id == id) return screen.name;
  }
  return null;
}

String? _shellPurpose(DesignBundle bundle, String id) {
  for (final screen in bundle.shell.screens) {
    if (screen.id == id) return screen.purpose;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Local drawing
// ---------------------------------------------------------------------------

/// `.cd` — the prototype's card, in the tones the content files use.
///
/// Rebuilt here rather than borrowed from the block renderer because these
/// cards carry live session state rather than authored JSON, and a block
/// renderer that had to accept arbitrary widgets would stop being a renderer.
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
          // A null callback leaves the card inert and draws no ink, which is
          // the correct affordance for a card that is only text.
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
                      color: dark
                          ? TetherColors.mutedOnDark
                          : TetherColors.muted,
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
                      color: dark
                          ? TetherColors.mutedOnDark
                          : TetherColors.muted,
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

/// `.rows` — the key-and-value list. Used for paused programs, which are
/// information rather than invitations.
class _RowsCard extends StatelessWidget {
  const _RowsCard({required this.items});

  final List<(String key, String value)> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TetherSpace.blockGap),
      child: Container(
        decoration: BoxDecoration(
          color: TetherColors.card,
          borderRadius: TetherRadius.blockAll,
          border: Border.all(color: TetherColors.line),
        ),
        // Stretch, not centre: a divider with loose constraints collapses to
        // nothing, which is a very quiet way to lose every hairline.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: TetherColors.rowDivider,
                ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(items[index].$1.toUpperCase(),
                        style: TetherText.rowKey),
                    const SizedBox(height: 2),
                    Text(items[index].$2, style: TetherText.rowValue),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A pill-shaped control inside a card.
///
/// Forty-four logical pixels tall whatever the label, because the labels here
/// are short enough that a text button's natural height would fall under the
/// minimum tap target.
class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.label,
    required this.onPressed,
    this.dark = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        tapTargetSize: MaterialTapTargetSize.padded,
        foregroundColor: dark ? Colors.white : TetherColors.ink,
        backgroundColor: dark ? TetherColors.inkSoft : TetherColors.cream,
        disabledForegroundColor: TetherColors.muted,
        textStyle: TetherText.chip,
        shape: const RoundedRectangleBorder(
          borderRadius: TetherRadius.pillAll,
        ),
      ),
      child: Text(label),
    );
  }
}
