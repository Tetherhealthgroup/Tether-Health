import 'package:flutter/material.dart';

import '../data/design_bundle.dart';
import '../journey/journey.dart';
import '../state/tether_scope.dart';
import '../theme/tether_tokens.dart';
import '../widgets/tether_page.dart';

/// A screen whose archetype exists and whose words do not.
///
/// This is most of the app. One area of eleven has a content file at all, and
/// inside that one ten of the thirty-four screens are still unwritten; every
/// screen in the other ten areas is in this state. Treating that as an error
/// case — a grey box, a "TODO", a crash — would render ninety-odd percent of
/// the product as a defect, which is both untrue and useless. The screens are
/// not broken. They are specified and unwritten, and the specification is
/// sitting right there in `archetypes.json`.
///
/// So this renderer shows the specification. The archetype's chrome is drawn
/// for real, its purpose is stated, every slot is listed with its cardinality
/// verbatim, its design notes are quoted, its safeguards are resolved to their
/// statements, and its declared actions are wired to whichever screens in this
/// journey carry the archetypes they point at. A writer opening this screen can
/// read off exactly what they have to produce; a reviewer can see what the
/// screen will be without reading JSON.
///
/// Every word this file contributes is chrome *about* the gap — never programme
/// copy. The banner says so out loud, in [Semantics] as well as on the page,
/// because a screen reader user has to be told that what follows is scaffolding
/// and not advice.
class UnwrittenScreen extends StatelessWidget {
  const UnwrittenScreen({
    required this.screen,
    required this.journey,
    required this.onNavigate,
    super.key,
  });

  final JourneyScreen screen;
  final Journey journey;

  /// Navigation is by screen id, as it is on an authored screen, so that the
  /// host resolves ids the same way whether or not the copy exists. A gap
  /// screen that navigated differently from a real one would be a second
  /// navigation model to keep in step.
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final archetype = screen.archetype;
    if (archetype == null) {
      // Readiness is derived from exactly this field, so a null archetype here
      // means a caller skipped `JourneyScreenHost`. There is nothing truthful
      // left to draw from, so say that rather than inventing a slot list.
      assert(
        false,
        'UnwrittenScreen was given ${screen.id}, whose archetype does not '
        'exist. Use JourneyScreenHost, which routes by readiness.',
      );
      return TetherPage(
        title: screen.archetypeId,
        leading: LeadingControl.back,
        headline: 'Nothing to show',
        sub: 'This screen has neither an archetype nor copy.',
        body: const [],
      );
    }

    final bundle = _bundleOrNull(context);
    final chrome = archetype.chrome;

    return TetherPage(
      title: archetype.name,
      leading: LeadingControl.parse(chrome.leading),
      // The archetype says whether this screen carries a status pill and a
      // progress hairline; it does not say what either reads, because that is
      // the content's job. Where the pill exists it is filled with the state
      // the screen is actually in, which is the most honest value available.
      badge: chrome.badge ? 'Unwritten' : null,
      // Likewise the hairline: the archetype declares one, nothing has said how
      // far through the flow this screen sits, so it is drawn empty rather than
      // guessed at a plausible-looking half.
      progress: chrome.progress ? 0.0 : null,
      headline: archetype.name,
      sub: archetype.purpose,
      body: [
        const _GapBanner(),
        _Facts(screen: screen, journey: journey),
        _Slots(archetype: archetype),
        if (archetype.notes case final String notes) _DesignNote(notes: notes),
        if (screen.rationale case final String rationale)
          _Rationale(
            rationale: rationale,
            origin: screen.origin,
            isShell: screen.isShell,
          ),
        _Safeguards(ids: archetype.requires, bundle: bundle),
      ],
      actions: [
        for (final action in archetype.actions) _archetypeActionButton(action),
      ],
      footer: 'Archetype ${archetype.id} · '
          '${archetype.slots.length} slots · '
          '${archetype.requiredSlots.length} required',
    );
  }

  /// The bundle, if a [TetherScope] is above this widget.
  ///
  /// [Journey] carries an [Area] and its screens, not the library they were
  /// resolved against, so safeguard ids cannot be turned into statements from
  /// the journey alone. The session in scope holds the bundle, which keeps the
  /// constructor the same shape as the other two renderers.
  ///
  /// The lookup is deliberately done by hand rather than through
  /// [TetherScope.of], which asserts when nothing is in scope. A widget test
  /// that pumps this screen on its own should get a page with raw safeguard ids
  /// on it, not a failed assertion: the ids alone are still true, and the
  /// screen's job is to degrade rather than disappear.
  DesignBundle? _bundleOrNull(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TetherScope>()
      ?.notifier
      ?.bundle;

  /// One of the archetype's declared actions, as a real button.
  ///
  /// Archetype actions point at *archetype ids* — `welcome` leads to `why` —
  /// whereas content actions point at screen ids. The two vocabularies meet
  /// here: the target is the screen in this journey drawn by that archetype,
  /// and where the journey has no such screen the button is rendered disabled
  /// for the same reason an authored screen's dead action is. The label names
  /// the destination rather than inventing a call to action, because a verb on
  /// this button would be programme copy that nobody has written.
  Widget _archetypeActionButton(ArchetypeAction action) {
    final target = _screenForArchetype(action.to);
    return TetherActionButton(
      label: target == null
          ? 'No screen for “${action.to}”'
          : 'Go to ${target.title}',
      kind: action.kind,
      onPressed: target == null ? null : () => onNavigate(target.id),
    );
  }

  /// The first screen in this journey built from [archetypeId].
  ///
  /// First rather than only: a product may use one archetype several times —
  /// LookUp draws four rescue screens — and from an unwritten screen there is
  /// no content to say which instance was meant. The first in delivery order is
  /// the one a reviewer walking the flow would reach next.
  JourneyScreen? _screenForArchetype(String archetypeId) {
    if (archetypeId.isEmpty) return null;
    for (final candidate in journey.screens) {
      if (candidate.archetypeId == archetypeId) return candidate;
    }
    return null;
  }
}

/// The statement that nothing below is approved.
///
/// It is first, it is coral, and it carries its own [Semantics] node so that a
/// screen reader announces the state of the screen before it reads any of the
/// scaffolding on it. Somebody arriving here by ear must not spend thirty
/// seconds listening to slot names before learning that none of it is copy.
class _GapBanner extends StatelessWidget {
  const _GapBanner();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Unwritten screen. The words for this screen have not been '
          'written. Nothing shown here is approved clinical content.',
      // The children keep their own nodes so the detail below is still
      // reachable; without this the label would swallow it.
      explicitChildNodes: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: TetherSpace.blockGap),
        padding: TetherSpace.cardPadding,
        decoration: BoxDecoration(
          color: TetherColors.coralPale,
          borderRadius: TetherRadius.blockAll,
          border: Border.all(color: TetherColors.coral),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('COPY NOT WRITTEN', style: TetherText.eyebrow),
            SizedBox(height: 4),
            Text(
              'The archetype for this screen exists. Its words do not.',
              style: TetherText.cardTitle,
            ),
            SizedBox(height: 6),
            Text(
              'Everything below is a description of what this screen has to '
              'contain, drawn from the shared archetype library. None of it is '
              'approved content, and none of it is advice.',
              style: TetherText.cardBody,
            ),
          ],
        ),
      ),
    );
  }
}

/// Where this screen sits: id, route, origin, and the two flags a reviewer
/// asks about first.
///
/// Cheap to render and expensive to look up by hand. A reviewer who cannot tell
/// whether a screen was pinned by a product file or derived from the area
/// catalogue cannot tell whether its absence of copy is an omission or a
/// proposal.
class _Facts extends StatelessWidget {
  const _Facts({required this.screen, required this.journey});

  final JourneyScreen screen;
  final Journey journey;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      eyebrow: 'SCREEN',
      children: [
        _KeyValue(label: 'Id', value: screen.id),
        _KeyValue(label: 'Archetype', value: screen.archetypeId),
        if (screen.route.isNotEmpty)
          _KeyValue(label: 'Route', value: screen.route),
        _KeyValue(label: 'Program', value: journey.area.name),
        _KeyValue(label: 'Origin', value: _originLabel(screen.origin)),
        if (screen.phase > 0)
          _KeyValue(label: 'Phase', value: '${screen.phase}'),
        if (screen.isShell)
          const _KeyValue(
            label: 'Shell',
            value: 'Built once, identical in every program',
          ),
        if (screen.isProposed)
          const _KeyValue(
            label: 'Status',
            value: 'Archetype proposed, not promoted',
          ),
      ],
    );
  }

  static String _originLabel(JourneyOrigin origin) => switch (origin) {
        JourneyOrigin.product => 'Pinned by the product file',
        JourneyOrigin.areaShared => 'Derived from the area’s shared screens',
        JourneyOrigin.areaSpecific =>
          'Derived from the area’s specific screens',
      };
}

/// Every slot the archetype declares, with its cardinality spec verbatim.
///
/// Verbatim matters. `required:3`, `required:0-2` and `required:first` are not
/// three ways of saying "required": the first fixes a count, the second gives a
/// ceiling the shell reads at runtime, and the third pins position — the crisis
/// card is `required:first` because a crisis route that scrolls is not a crisis
/// route. Paraphrasing any of them into a tick and a cross would throw away the
/// part the writer actually needs.
class _Slots extends StatelessWidget {
  const _Slots({required this.archetype});

  final Archetype archetype;

  @override
  Widget build(BuildContext context) {
    if (archetype.slots.isEmpty) {
      return const _Panel(
        eyebrow: 'SLOTS',
        children: [
          Text(
            'This archetype declares no slots.',
            style: TetherText.cardBody,
          ),
        ],
      );
    }

    final entries = archetype.slots.entries.toList(growable: false);
    return _Panel(
      eyebrow: 'SLOTS TO FILL',
      children: [
        for (final (index, entry) in entries.indexed) ...[
          if (index > 0) const _Hairline(),
          _SlotRow(name: entry.key, spec: entry.value),
        ],
      ],
    );
  }
}

/// One slot: its name, and its spec as a pill.
///
/// Required and optional are distinguished by weight and colour rather than by
/// grouping, so the list stays in the order the archetype declares it. That
/// order is the reading order of the finished screen — headline before sub
/// before cards — and re-sorting it into two buckets would lose it.
class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.name, required this.spec});

  final String name;
  final String spec;

  /// `required`, `required:3`, `required:0-2` and `required:first` all count.
  /// Anything else — in practice `optional` and `optional:2` — does not.
  bool get _isRequired => spec.startsWith('required');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              name,
              // Wraps rather than clips: slot names such as
              // `primaryMetricCard` and `scopeDisclaimer` run out of room at
              // 320px once the text scale is turned up, and a truncated slot
              // name is not a slot name.
              softWrap: true,
              style: TetherText.cardTitle.copyWith(
                fontWeight: _isRequired ? FontWeight.w600 : FontWeight.w400,
                color: _isRequired ? TetherColors.ink : TetherColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SpecPill(spec: spec, emphasised: _isRequired),
        ],
      ),
    );
  }
}

/// The cardinality spec, drawn as a chip so it reads as data rather than prose.
class _SpecPill extends StatelessWidget {
  const _SpecPill({required this.spec, required this.emphasised});

  final String spec;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: emphasised ? TetherColors.mint : TetherColors.cream,
        borderRadius: TetherRadius.pillAll,
        border: Border.all(
          color: emphasised ? TetherColors.mint : TetherColors.line,
        ),
      ),
      child: Text(spec, style: TetherText.chip),
    );
  }
}

/// The archetype's design note, quoted.
///
/// These are the sentences the bundle's authors left behind to explain why a
/// screen is shaped the way it is — "the skip must exist", "one action, never a
/// list of five", "reduction is never presented as a safe endpoint". They are
/// the constraints most likely to be violated by somebody filling slots quickly
/// and in good faith, which is exactly why they are shown on the screen being
/// filled rather than left in a file nobody rereads. Quoted, not paraphrased:
/// the note is the bundle's voice, not this app's.
class _DesignNote extends StatelessWidget {
  const _DesignNote({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: TetherSpace.blockGap),
      padding: TetherSpace.cardPadding,
      decoration: const BoxDecoration(
        color: TetherColors.mintPale,
        borderRadius: TetherRadius.blockAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DESIGN NOTE', style: TetherText.eyebrow),
          const SizedBox(height: 6),
          Text(
            '“$notes”',
            style: TetherText.cardBody.copyWith(
              color: TetherColors.ink,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Why the area asked for this screen.
///
/// Only screens the catalogue proposes carry one, and for shell screens the
/// journey builder puts the shell's stated purpose here instead. Both answer
/// the same question a reviewer has when a screen has no copy: is this screen
/// meant to exist at all?
class _Rationale extends StatelessWidget {
  const _Rationale({
    required this.rationale,
    required this.origin,
    required this.isShell,
  });

  final String rationale;
  final JourneyOrigin origin;

  /// A shell screen's rationale is `shell.json`'s stated purpose rather than a
  /// request from the area, and mislabelling it would tell a reviewer this area
  /// asked for a screen that every area gets whether it asks or not.
  final bool isShell;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      eyebrow: switch ((isShell, origin)) {
        (true, _) => 'WHAT THE SHELL SAYS THIS SCREEN IS FOR',
        (_, JourneyOrigin.product) => 'WHY IT IS PROPOSED',
        _ => 'WHY THIS AREA ASKED FOR IT',
      },
      children: [Text(rationale, style: TetherText.cardBody)],
    );
  }
}

/// The safeguards this archetype cannot ship without, resolved to statements.
///
/// An id on its own — `slip_never_resets` — is a reminder for somebody who
/// already knows the rule. The statement is the rule. Since these are the
/// constraints the bundle describes as "most likely to be quietly violated by
/// someone shipping fast", the writer filling this screen's slots is precisely
/// the person who needs to read them in full.
///
/// An id the bundle cannot resolve is shown as the bare id rather than dropped,
/// which is also what happens when no session is in scope. Silence would read
/// as "no safeguards apply", and that is the one wrong answer.
class _Safeguards extends StatelessWidget {
  const _Safeguards({required this.ids, required this.bundle});

  final List<String> ids;
  final DesignBundle? bundle;

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) {
      return const _Panel(
        eyebrow: 'SAFEGUARDS',
        children: [
          Text(
            'This archetype declares none of its own. The program’s area-level '
            'safeguards still apply.',
            style: TetherText.cardBody,
          ),
        ],
      );
    }

    return _Panel(
      eyebrow: 'CANNOT SHIP WITHOUT',
      children: [
        for (final (index, id) in ids.indexed) ...[
          if (index > 0) const _Hairline(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bundle?.safeguards[id]?.name ?? id,
                  style: TetherText.cardTitle,
                ),
                if (bundle?.safeguards[id]?.statement
                    case final String statement) ...[
                  const SizedBox(height: 4),
                  Text(statement, style: TetherText.cardBody),
                ],
                const SizedBox(height: 4),
                Text(id, style: TetherText.footnote),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A plain white card with an uppercase eyebrow.
///
/// Local to this file rather than shared: the gap renderers are the only part
/// of the app allowed to invent layout, since everything else is transcribed
/// from the prototype, and pushing a general-purpose card into the shared
/// widget set would invite the rest of the product to drift away from the
/// prototype through it.
class _Panel extends StatelessWidget {
  const _Panel({required this.eyebrow, required this.children});

  final String eyebrow;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: TetherSpace.blockGap),
      padding: TetherSpace.cardPadding,
      decoration: const BoxDecoration(
        color: TetherColors.card,
        borderRadius: TetherRadius.blockAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: TetherText.eyebrow),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

/// A labelled fact. The key wraps onto its own line rather than squeezing the
/// value, which is what keeps this readable at 320px with large text.
class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TetherText.rowKey),
          Text(value, style: TetherText.rowValue),
        ],
      ),
    );
  }
}

/// The divider between rows inside a panel, matching `.rw` in the prototype.
class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: TetherColors.rowDivider);
}
