/// SH5 — Who sees what.
///
/// `shell.json`'s `per_program_sharing` rule is the one on this list that is
/// hardest to undo if it is got wrong: "sharing consent is granted per
/// program, never globally", because "under 42 CFR Part 2, substance-use data
/// must be segregated regardless" of what the person would otherwise agree to.
/// A single global switch would be simpler to build, simpler to explain, and
/// would quietly merge two legally distinct disclosures into one.
///
/// So this screen never offers a control that spans programs. Every switch
/// writes through [TetherSession.setSharing] for one area id, and the rows are
/// drawn side by side for exactly the reason the shell spec gives — "shown
/// side by side so the differences are visible". A person should be able to
/// see at a glance that their cessation coach and their behavioural health
/// coach are not the same audience.
///
/// Everything starts off. [SharingSetting] defaults both flags to false and
/// nothing on this screen changes that on the person's behalf.
library;

import 'package:flutter/material.dart';

import '../../data/design_bundle.dart';
import '../../state/tether_scope.dart';
import '../../state/tether_session.dart';
import '../../theme/tether_tokens.dart';
import '../../widgets/tether_page.dart';
import 'shell_routes.dart';

/// Per-program sharing, one row per joined program.
class SharingMatrixScreen extends StatelessWidget {
  const SharingMatrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = TetherScope.of(context);
    final bundle = session.bundle;

    // Joined, not just active. A paused program still holds history, and a
    // sharing setting left switched on across a pause is exactly the kind of
    // thing a person needs to be able to see.
    final joined = [
      for (final area in bundle.areas)
        if (session.enrolment(area.id).isJoined) session.enrolment(area.id),
    ];

    return TetherPage(
      title: _shellName(bundle, 'SH5') ?? 'Who sees what',
      badge: 'Private',
      leading: LeadingControl.back,
      headline: 'Sharing is set per program.',
      sub: 'Nothing is pooled between them, and nothing is shared by default.',
      body: [
        // programRows — "required".
        if (joined.isEmpty)
          const _ShellCard(
            // TODO(copy): empty-state title for somebody with no programs.
            title: 'Nothing to share yet',
            // TODO(copy): empty-state body. Restates the default so that the
            // screen is still informative when it is empty.
            body: 'When you join a program, its own sharing settings appear here — switched off, and separate from every other program.',
          )
        else
          for (final enrolment in joined)
            _ProgramSharingRow(enrolment: enrolment),

        // segregationNote — "optional" in the slot spec, present always here.
        // The rule it explains is not optional.
        _ShellCard(
          tone: CardTone.mintPale,
          title: 'Why they are separate',
          body: 'A cessation coach has no reason to see behavioural health data. Some categories are legally required to stay segregated.',
          children: [
            if (bundle.shell.rule('per_program_sharing') case final ShellRule rule) ...[
              const SizedBox(height: 10),
              Text(rule.why, style: TetherText.cardBody),
            ],
          ],
        ),

        const _ShellCard(
          title: 'Preview before sending',
          body: 'Every share shows you the exact contents first. You can cancel at that point.',
          children: [
            SizedBox(height: 8),
            Text(
              // TODO(copy): the honest qualifier. The card above describes a
              // commitment the product makes; this build has no transport at
              // all, so nothing has ever left the phone and the screen should
              // not let the promise imply that something has.
              'In this build nothing is sent anywhere. These switches record what you have agreed to, and there is no recipient behind them yet.',
              style: TetherText.cardBody,
            ),
          ],
        ),

        if (bundle.safeguards['share_on_request_only']
            case final Safeguard safeguard)
          _ShellCard(
            tone: CardTone.mintPale,
            // TODO(copy): eyebrow over a quoted safeguard.
            eyebrow: 'The rule behind this screen',
            title: safeguard.name,
            body: safeguard.statement,
          ),
      ],
      actions: [
        TetherActionButton(
          label: 'Back',
          kind: 'ghost',
          onPressed: () => _back(context),
        ),
      ],
      footer: 'Changing a setting here affects one program only.',
    );
  }
}

/// One program's sharing, with its two switches.
///
/// Totals and notes are separate controls rather than one "share my data"
/// switch because they are different disclosures: a coach seeing an adherence
/// total is not the same event as a coach reading what somebody wrote at 2am.
/// [SharingSetting] models them separately for that reason, and collapsing
/// them in the UI would undo it.
class _ProgramSharingRow extends StatelessWidget {
  const _ProgramSharingRow({required this.enrolment});

  final Enrolment enrolment;

  @override
  Widget build(BuildContext context) {
    final session = TetherScope.of(context);
    final sharing = enrolment.sharing;
    final name = _displayName(session, enrolment.areaId);
    final recipient = sharing.recipient;

    return _ShellCard(
      eyebrow: recipient == null
          ? name
          // The authored rows read "LOOKUP → MAYA". The arrow is the whole
          // point of the row: it names an audience, not a setting.
          : '$name → $recipient',
      title: sharing.sharesAnything
          // TODO(copy): the summary line when something is on. The authored
          // row reads "Totals and adherence · notes off".
          ? _summary(sharing)
          : 'Nothing shared',
      body: recipient == null
          // TODO(copy): what to say when nobody has been named yet.
          ? 'No-one has been named for this program.'
          : null,
      children: [
        const SizedBox(height: 6),
        _SharingSwitch(
          // The authored wording for this disclosure, kept exactly.
          label: 'Totals and adherence',
          // TODO(copy): the explanatory line under the switch.
          description: 'Aggregate progress for this program. Nothing from any other program.',
          value: sharing.totalsAndAdherence,
          programName: name,
          onChanged: (value) => session.setSharing(
            enrolment.areaId,
            sharing.copyWith(totalsAndAdherence: value),
          ),
        ),
        _SharingSwitch(
          label: 'Notes',
          // TODO(copy): the explanatory line under the switch.
          description: 'Anything you wrote in your own words.',
          value: sharing.notes,
          programName: name,
          onChanged: (value) => session.setSharing(
            enrolment.areaId,
            sharing.copyWith(notes: value),
          ),
        ),
      ],
    );
  }
}

/// One switch, announced with the program it belongs to.
///
/// The program name is in the semantic label rather than only in the card
/// heading above it, because a screen reader moving switch by switch would
/// otherwise hear "Notes, off" four times with nothing to tell them apart —
/// on the one screen whose entire purpose is telling programs apart.
class _SharingSwitch extends StatelessWidget {
  const _SharingSwitch({
    required this.label,
    required this.description,
    required this.value,
    required this.programName,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final String programName;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label for $programName',
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TetherText.rowValue),
                  const SizedBox(height: 2),
                  Text(description, style: TetherText.cardBody),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // `Switch` already reports its own checked state and a 48px tap
            // target, so the Semantics above only has to supply the thing it
            // cannot know: which program this is.
            Switch(
              value: value,
              onChanged: onChanged,
              // Resolved per state rather than set through the `activeColor`
              // family, which is deprecated and would break the analysis gate.
              thumbColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? TetherColors.ink
                    : TetherColors.card,
              ),
              trackColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? TetherColors.mint
                    : TetherColors.line,
              ),
              trackOutlineColor:
                  const WidgetStatePropertyAll<Color>(TetherColors.line),
            ),
          ],
        ),
      ),
    );
  }
}

/// The one-line summary above a program's switches.
String _summary(SharingSetting sharing) {
  if (sharing.totalsAndAdherence && sharing.notes) {
    // TODO(copy): both switches on.
    return 'Totals and adherence · notes on';
  }
  if (sharing.notes) {
    // TODO(copy): notes only, which is an unusual combination worth naming.
    return 'Notes only · no totals';
  }
  // The authored summary, kept exactly.
  return 'Totals and adherence · notes off';
}

String _displayName(TetherSession session, String areaId) {
  final product = session.bundle.productForArea(areaId);
  if (product != null) return product.name;
  return session.bundle.area(areaId)?.name ?? areaId;
}

String? _shellName(DesignBundle bundle, String id) {
  for (final screen in bundle.shell.screens) {
    if (screen.id == id) return screen.name;
  }
  return null;
}

void _back(BuildContext context) {
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

/// `.cd` — the prototype's card. See `programs_home_screen.dart` for why the
/// shell screens draw their own.
class _ShellCard extends StatelessWidget {
  const _ShellCard({
    this.tone = CardTone.plain,
    this.eyebrow,
    this.title,
    this.body,
    this.children = const <Widget>[],
  });

  final CardTone tone;
  final String? eyebrow;
  final String? title;
  final String? body;
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
        // Nothing here is a navigation target. The controls on this screen are
        // the switches, and a tappable card around them would be a second,
        // ambiguous way to change a consent setting.
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
    );
  }
}
