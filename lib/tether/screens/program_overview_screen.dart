import 'package:flutter/material.dart';

import '../data/design_bundle.dart';
import '../journey/journey.dart';
import '../state/tether_scope.dart';
import '../theme/tether_tokens.dart';
import '../widgets/tether_page.dart';
import 'journey_screen_host.dart';

/// One program's index, and how much of it exists.
///
/// This replaces the coverage panel `tools/prototype.py` prints down the right
/// hand side of its generated page. That panel lists how many of a product's
/// screens have content, names the ones that do not, and names every button
/// that points at a screen the content file does not supply — and it is a
/// desktop artefact in two ways that matter. It needs a wide window to sit
/// beside the phone, and it can only run for a product that already has a
/// content file, because it loads one before it draws anything. Nine of the
/// eleven areas have neither a product file nor a content file, so the panel
/// cannot say anything at all about most of the product.
///
/// On the device the same information has to arrive in a column, and it has to
/// work for a journey that was derived from the area catalogue rather than
/// authored. That is the whole reason this screen exists: eleven half-built
/// programs are only reviewable if the app itself will tell you which parts are
/// built. Everything on it is computed from [Journey] — nothing is a stored
/// number that could fall out of step with the JSON.
///
/// It is also the one screen in this package that uses [Navigator] directly.
/// The three renderers navigate by screen id and leave resolution to their
/// caller; here the caller is this widget, so this is where ids become routes.
class ProgramOverviewScreen extends StatelessWidget {
  const ProgramOverviewScreen({required this.journey, super.key});

  final Journey journey;

  @override
  Widget build(BuildContext context) {
    final area = journey.area;
    final entry = journey.entry;
    final bundle = _bundleOrNull(context);

    return TetherPage(
      title: 'Program',
      leading: LeadingControl.back,
      // Authored or generated is the first thing a reviewer needs, and it is
      // the difference between a decision somebody made and a proposal this app
      // derived, so it goes in the one piece of chrome that is always visible.
      badge: journey.isGenerated ? 'Derived' : 'Authored',
      headline: area.name,
      sub: area.scope,
      body: [
        _Provenance(journey: journey),
        _Coverage(journey: journey),
        _DeadEnds(journey: journey),
        _Safeguards(journey: journey, bundle: bundle),
        _ScreenList(
          journey: journey,
          onOpen: (screen) => _open(context, screen),
        ),
      ],
      actions: [
        TetherActionButton(
          label: entry == null
              ? 'This program has no screens'
              : 'Open ${entry.title}',
          onPressed: entry == null ? null : () => _open(context, entry),
        ),
      ],
      footer: '${journey.screens.length} screens · locale ${journey.locale}',
    );
  }

  /// The bundle, if a [TetherScope] is above this widget.
  ///
  /// Only used to turn safeguard ids into names. Looked up by hand rather than
  /// through [TetherScope.of] so that a widget test pumping this screen on its
  /// own gets the ids instead of a failed assertion — the ids are the part the
  /// journey actually asserts, and the names are a courtesy.
  DesignBundle? _bundleOrNull(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TetherScope>()?.notifier?.bundle;

  /// Pushes one screen, and keeps pushing as it is navigated.
  ///
  /// A journey is a graph, not a stack, so a person walking it from here builds
  /// up a back stack that mirrors the path they took rather than the structure
  /// of the program. For a review surface that is the right behaviour: back
  /// retraces the route that was demonstrated, which is exactly what a person
  /// showing somebody else a flow expects.
  void _open(BuildContext context, JourneyScreen screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => JourneyScreenHost(
          screen: screen,
          journey: journey,
          onNavigate: (id) {
            final next = journey.screen(id);
            // Unreachable through the renderers, which disable any action whose
            // target is not in the journey. Ignored rather than asserted
            // because a review surface should not crash on a bad id in a
            // content file that is mid-edit; the dead end is already reported
            // in the panel above.
            if (next != null) _open(routeContext, next);
          },
        ),
      ),
    );
  }
}

/// Where this journey came from.
///
/// A product file pins ids, routes, phases and order — somebody chose them. A
/// derived journey is this app reading the area's own `screens.shared` and
/// `screens.specific` lists and putting them in the shared library's order. The
/// second is a legitimate, useful thing to review, but it is a proposal, and
/// the panel says which one is on screen before it says anything else.
class _Provenance extends StatelessWidget {
  const _Provenance({required this.journey});

  final Journey journey;

  @override
  Widget build(BuildContext context) {
    final product = journey.product;
    return _Panel(
      eyebrow: journey.isGenerated ? 'DERIVED PROGRAM' : 'AUTHORED PROGRAM',
      children: [
        Text(
          journey.isGenerated
              ? 'No product file exists for this area, so the screen list was '
                'derived from the area catalogue and ordered by the shared '
                'library. Treat it as a proposal: nobody has chosen these '
                'routes or this delivery order.'
              : 'The screen list, routes and delivery phases come from a '
                'product file. Somebody chose them.',
          style: TetherText.cardBody,
        ),
        const SizedBox(height: 6),
        if (product != null) ...[
          _KeyValue(label: 'Product', value: '${product.name} (${product.id})'),
          _KeyValue(label: 'Product status', value: product.status),
        ],
        _KeyValue(label: 'Area', value: journey.area.id),
        _KeyValue(label: 'Area status', value: journey.area.status.label),
        if (journey.area.hasClinicalThresholds)
          const _KeyValue(
            label: 'Clinical thresholds',
            value: 'Carries a measure with clinical thresholds',
          ),
      ],
    );
  }
}

/// How many screens are in each state.
///
/// Three numbers, side by side, in the order a screen travels through them.
/// This is the number the coverage panel led with — "24 of 34 screens" — split
/// into the two different kinds of missing, because "no copy" and "no
/// archetype" are hours apart in effort and nothing else in the app
/// distinguishes them at a glance.
class _Coverage extends StatelessWidget {
  const _Coverage({required this.journey});

  final Journey journey;

  @override
  Widget build(BuildContext context) {
    final authored = journey.withReadiness(JourneyReadiness.authored).length;
    final unwritten = journey.awaitingCopy.length;
    final unbuilt = journey.awaitingArchetype.length;

    return _Panel(
      eyebrow: 'COVERAGE',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Tile(value: '$authored', label: 'Authored')),
            const SizedBox(width: TetherSpace.statGap),
            Expanded(child: _Tile(value: '$unwritten', label: 'Copy to write')),
            const SizedBox(width: TetherSpace.statGap),
            Expanded(child: _Tile(value: '$unbuilt', label: 'Not built')),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$authored of ${journey.screens.length} screens can be drawn as a '
          'person would see them.',
          style: TetherText.cardBody,
        ),
      ],
    );
  }
}

/// The bundle's first acceptance test, run live.
///
/// "No dead ends" is the test, and [Journey.deadEnds] is the test: every
/// destination any screen points at that no screen in this journey supplies.
/// It counts tappable cards as well as buttons, because a card that goes
/// nowhere is the same broken promise as a button that does.
///
/// An authored screen renders an action with a missing target as a disabled
/// button, so an id listed here is a dead button over there and the two
/// surfaces cannot drift apart.
class _DeadEnds extends StatelessWidget {
  const _DeadEnds({required this.journey});

  final Journey journey;

  @override
  Widget build(BuildContext context) {
    final dead = journey.deadEnds.toList()..sort();

    if (dead.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: TetherSpace.blockGap),
        padding: TetherSpace.cardPadding,
        decoration: const BoxDecoration(
          color: TetherColors.mint,
          borderRadius: TetherRadius.blockAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DEAD ENDS', style: TetherText.eyebrow),
            const SizedBox(height: 6),
            Text(
              'None. Every button and every tappable card in this program '
              'lands on a screen the program lists.',
              style: TetherText.cardBody.copyWith(color: TetherColors.ink),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: TetherSpace.blockGap),
      padding: TetherSpace.cardPadding,
      decoration: BoxDecoration(
        color: TetherColors.coralPale,
        borderRadius: TetherRadius.blockAll,
        border: Border.all(color: TetherColors.coral),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DEAD ENDS — ${dead.length}', style: TetherText.eyebrow),
          const SizedBox(height: 6),
          const Text(
            'Something in this program points at these, and this program has '
            'no screen for them. Buttons pointing here are rendered disabled '
            'rather than left live.',
            style: TetherText.cardBody,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: TetherSpace.chipGap,
            runSpacing: TetherSpace.chipGap,
            children: [
              for (final id in dead)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: TetherColors.card,
                    borderRadius: TetherRadius.pillAll,
                    border: Border.all(color: TetherColors.coral),
                  ),
                  child: Text(id, style: TetherText.chip),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Every safeguard binding this program.
///
/// [Journey.safeguardIds] is the union of what the area declares and what each
/// of its archetypes says it cannot ship without, which is the only place those
/// two lists are ever added together. A reviewer looking at one screen sees
/// that screen's constraints; this is the set the whole program is held to.
class _Safeguards extends StatelessWidget {
  const _Safeguards({required this.journey, required this.bundle});

  final Journey journey;
  final DesignBundle? bundle;

  @override
  Widget build(BuildContext context) {
    final ids = journey.safeguardIds.toList()..sort();
    if (ids.isEmpty) {
      return const _Panel(
        eyebrow: 'SAFEGUARDS IN FORCE',
        children: [
          Text(
            'This program declares none, which is itself worth checking.',
            style: TetherText.cardBody,
          ),
        ],
      );
    }

    return _Panel(
      eyebrow: 'SAFEGUARDS IN FORCE — ${ids.length}',
      children: [
        for (final (index, id) in ids.indexed) ...[
          if (index > 0) const _Hairline(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The name where the bundle is in scope, the raw id otherwise.
                // Never nothing: an unresolvable safeguard id is a finding, and
                // dropping it would hide it.
                Text(
                  bundle?.safeguards[id]?.name ?? id,
                  style: TetherText.rowValue,
                ),
                Text(id, style: TetherText.footnote),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The index: every screen, in delivery order, tappable.
///
/// Ordered by phase and then by the position the journey already put them in.
/// Phase only exists on a product journey — a derived one is all phase zero —
/// so for nine of the eleven areas this is simply the shared library's order,
/// which is the order the builder chose so that welcome comes before consent
/// and rescue before recheck in every area.
class _ScreenList extends StatelessWidget {
  const _ScreenList({required this.journey, required this.onOpen});

  final Journey journey;
  final ValueChanged<JourneyScreen> onOpen;

  @override
  Widget build(BuildContext context) {
    // Sorted on a copy paired with its original index, because Dart's sort is
    // not stable and the within-phase order is the delivery order that the
    // journey builder was careful to establish.
    final ordered = journey.screens.indexed.toList()
      ..sort((a, b) {
        final byPhase = a.$2.phase.compareTo(b.$2.phase);
        return byPhase != 0 ? byPhase : a.$1.compareTo(b.$1);
      });

    return _Panel(
      eyebrow: 'SCREENS — ${journey.screens.length}',
      children: [
        for (final (index, entry) in ordered.indexed) ...[
          if (index > 0) const _Hairline(),
          _ScreenRow(screen: entry.$2, onOpen: () => onOpen(entry.$2)),
        ],
      ],
    );
  }
}

/// One screen in the index.
///
/// Id, title, archetype and readiness, in that order, because the id is what a
/// reviewer is holding in their hand when they come looking. Readiness is drawn
/// as a chip on its own line rather than in a trailing column so that a long
/// title wraps instead of squeezing it off the screen at 320px.
class _ScreenRow extends StatelessWidget {
  const _ScreenRow({required this.screen, required this.onOpen});

  final JourneyScreen screen;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    // Merged rather than labelled by hand: the row's own text already says the
    // id, the archetype, the title and the readiness, and [InkWell] supplies
    // the button role and the tap action. Adding a [Semantics] label over the
    // top would either duplicate all of that or, if the children were excluded,
    // throw away the tap action that makes the row activatable.
    return MergeSemantics(
      child: InkWell(
        onTap: onOpen,
        borderRadius: TetherRadius.optionAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${screen.id}  ·  ${screen.archetypeId}',
                      style: TetherText.rowKey,
                    ),
                    const SizedBox(height: 2),
                    Text(screen.title, style: TetherText.rowValue),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: TetherSpace.chipGap,
                      runSpacing: 4,
                      children: [
                        _ReadinessChip(readiness: screen.readiness),
                        if (screen.isShell) const _FlagChip(label: 'Shell'),
                        if (screen.isProposed)
                          const _FlagChip(label: 'Proposed'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: TetherColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The readiness of one screen, as a chip.
///
/// Mint for a screen that draws, coral for one that does not exist, and a plain
/// outline for one that is specified and unwritten — the middle state is the
/// common one and does not deserve an alarm colour, because it is what most of
/// an eleven-area product looks like while it is being written.
class _ReadinessChip extends StatelessWidget {
  const _ReadinessChip({required this.readiness});

  final JourneyReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final (background, border) = switch (readiness) {
      JourneyReadiness.authored => (TetherColors.mint, TetherColors.mint),
      // Approved artwork is finished, so it reads as finished — but not
      // identically to authored slots, because the two are reviewed and
      // changed by completely different processes.
      JourneyReadiness.artwork => (TetherColors.mintPale, TetherColors.mint),
      JourneyReadiness.awaitingCopy => (TetherColors.cream, TetherColors.line),
      JourneyReadiness.awaitingArchetype => (
          TetherColors.coralPale,
          TetherColors.coral,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: TetherRadius.pillAll,
        border: Border.all(color: border),
      ),
      child: Text(_readinessLabel(readiness), style: TetherText.chip),
    );
  }
}

/// A flag that is not about readiness: shell-supplied, or a proposed archetype.
class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: TetherColors.mintPale,
        borderRadius: TetherRadius.pillAll,
        border: Border.all(color: TetherColors.mintPale),
      ),
      child: Text(label, style: TetherText.chip),
    );
  }
}

/// Words rather than enum names, because this text is read aloud by a screen
/// reader as well as shown.
String _readinessLabel(JourneyReadiness readiness) => switch (readiness) {
      JourneyReadiness.authored => 'Authored',
      JourneyReadiness.artwork => 'Approved artwork',
      JourneyReadiness.awaitingCopy => 'Copy to write',
      JourneyReadiness.awaitingArchetype => 'Not built',
    };

/// A stat tile, matching `.st` in the prototype.
///
/// Sized by its caller rather than by itself: the three tiles are wrapped in
/// [Expanded] at the call site so that a tile stays usable if it is ever put
/// somewhere other than an equal-thirds row.
class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: const BoxDecoration(
        color: TetherColors.cream,
        borderRadius: TetherRadius.statAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TetherText.statValue),
          const SizedBox(height: 2),
          Text(label, style: TetherText.statLabel),
        ],
      ),
    );
  }
}

/// A plain white card with an uppercase eyebrow.
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

/// A labelled fact, stacked so neither half is squeezed at 320px.
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

/// The divider between rows inside a panel, matching `.rw`.
class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: TetherColors.rowDivider);
}
