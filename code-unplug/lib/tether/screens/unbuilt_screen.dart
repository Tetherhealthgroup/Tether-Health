import 'package:flutter/material.dart';

import '../data/design_bundle.dart';
import '../journey/journey.dart';
import '../theme/tether_tokens.dart';
import '../widgets/tether_page.dart';

/// A screen whose archetype has not been built.
///
/// The two other readiness states describe work in progress; this one describes
/// work that has not started, and the difference is worth a whole renderer.
/// `age_gate`, `intercept` and `environment` are the three the bundle names as
/// awaiting promotion, and several areas name others of their own. There is no
/// slot list to show, no chrome to honour and no purpose statement to quote,
/// because none of those exist anywhere: the archetype is an id in a catalogue
/// and nothing more.
///
/// So this screen draws the one thing that *is* known — the id, who asked for
/// it, and why — and then stops. Inventing a plausible layout for an archetype
/// nobody has designed would be the most expensive kind of lie: it would look
/// like progress, it would get screenshotted, and somebody would eventually
/// have to explain that the screen in the deck does not exist and never did.
///
/// The rationale is the load-bearing field. The bundle's rule for adding an
/// area asks not just why a new archetype is needed but *which other areas
/// could reuse it*, and that second half is the test that stops the shared
/// library fragmenting into eleven bespoke products. Showing it here puts the
/// test in front of the person deciding whether to build the thing.
class UnbuiltScreen extends StatelessWidget {
  const UnbuiltScreen({
    required this.screen,
    required this.journey,
    required this.onNavigate,
    super.key,
  });

  final JourneyScreen screen;
  final Journey journey;

  /// Kept for symmetry with the other two renderers so `JourneyScreenHost` can
  /// hand all three the same three arguments. This screen has exactly one
  /// destination — the program's entry — and it navigates by id like everything
  /// else, so the host stays the only thing that knows how ids become pages.
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final entry = journey.entry;
    // Offering a way back to the screen the person is already on is worse than
    // offering nothing: it reads as a working button that does nothing. Held as
    // a nullable local rather than a boolean so that the null check promotes
    // and the label can name the destination.
    final target = entry != null && entry.id != screen.id ? entry : null;

    return TetherPage(
      title: screen.archetypeId,
      // Back rather than close. There is no flow to leave — this screen is not
      // part of one yet — so the only honest control is the one that undoes
      // arriving here.
      leading: LeadingControl.back,
      badge: 'Not built',
      headline: 'This screen has not been built',
      sub: 'The ${journey.area.name} program asks for an archetype that the '
          'shared library does not define. Nothing has been designed for it '
          'yet, so there is nothing here to show.',
      body: [
        _GapBanner(archetypeId: screen.archetypeId),
        _Facts(screen: screen, journey: journey),
        if (screen.rationale case final String rationale)
          _Rationale(rationale: rationale, origin: screen.origin),
        _WhatWouldHaveToHappen(archetypeId: screen.archetypeId),
      ],
      actions: [
        TetherActionButton(
          label: target == null
              ? 'No entry screen in this program'
              : 'Back to ${target.title}',
          kind: 'ghost',
          onPressed: target == null ? null : () => onNavigate(target.id),
        ),
      ],
      footer: 'Archetype “${screen.archetypeId}” is referenced by '
          '${journey.area.name} and is not in the shared library.',
    );
  }
}

/// The statement of absence, announced as one unit.
///
/// It carries its own [Semantics] label for the same reason the unwritten
/// screen's banner does: somebody reading by ear has to learn that the screen
/// does not exist before they are read anything else about it.
class _GapBanner extends StatelessWidget {
  const _GapBanner({required this.archetypeId});

  final String archetypeId;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Not built. The archetype $archetypeId does not exist in the '
          'shared library, so this screen has not been designed.',
      explicitChildNodes: true,
      child: Container(
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
            const Text(
              'ARCHETYPE NOT IN THE LIBRARY',
              style: TetherText.eyebrow,
            ),
            const SizedBox(height: 4),
            Text(
              archetypeId,
              softWrap: true,
              style: TetherText.cardTitle,
            ),
            const SizedBox(height: 6),
            const Text(
              'No purpose, no slots, no chrome and no safeguards have been '
              'written for it. This page is a placeholder for a screen that '
              'does not exist, and nothing on it is content.',
              style: TetherText.cardBody,
            ),
          ],
        ),
      ),
    );
  }
}

/// The little that is known: the id, the area that asked, and where the request
/// came from.
class _Facts extends StatelessWidget {
  const _Facts({required this.screen, required this.journey});

  final JourneyScreen screen;
  final Journey journey;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      eyebrow: 'WHAT IS KNOWN',
      children: [
        _KeyValue(label: 'Archetype id', value: screen.archetypeId),
        _KeyValue(label: 'Asked for by', value: journey.area.name),
        if (journey.area.scope.isNotEmpty)
          _KeyValue(label: 'Area scope', value: journey.area.scope),
        _KeyValue(label: 'Screen id', value: screen.id),
        if (screen.route.isNotEmpty)
          _KeyValue(label: 'Route it would live at', value: screen.route),
        _KeyValue(label: 'Origin', value: _originLabel(screen.origin)),
        if (screen.phase > 0)
          _KeyValue(label: 'Delivery phase', value: '${screen.phase}'),
      ],
    );
  }

  static String _originLabel(JourneyOrigin origin) => switch (origin) {
        JourneyOrigin.product =>
          'Named by the product file, which expects it to exist',
        JourneyOrigin.areaShared =>
          'Named in the area’s shared screen list, which expects it to exist',
        JourneyOrigin.areaSpecific =>
          'Proposed by the area as a screen the library does not have',
      };
}

/// The rationale from the catalogue, quoted.
///
/// Half of it is the reason the area wants the screen; the other half is meant
/// to name the areas that could reuse it. That second half is the promotion
/// test, and a rationale that does not answer it is itself a finding a reviewer
/// should be able to make at a glance — which they can only do if the text is
/// shown as written rather than summarised.
class _Rationale extends StatelessWidget {
  const _Rationale({required this.rationale, required this.origin});

  final String rationale;
  final JourneyOrigin origin;

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
          Text(
            origin == JourneyOrigin.areaSpecific
                ? 'WHY IT IS PROPOSED, AND WHO ELSE COULD USE IT'
                : 'WHY THIS SCREEN IS ASKED FOR',
            style: TetherText.eyebrow,
          ),
          const SizedBox(height: 6),
          Text(
            '“$rationale”',
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

/// What building it would take, stated plainly.
///
/// Not a roadmap and not a promise — a description of where the work lands.
/// The bundle keeps the archetype library in one file precisely so that this
/// answer is the same for every unbuilt screen in every area, and saying it out
/// loud is cheaper than eleven people each working it out.
class _WhatWouldHaveToHappen extends StatelessWidget {
  const _WhatWouldHaveToHappen({required this.archetypeId});

  final String archetypeId;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      eyebrow: 'TO BUILD IT',
      children: [
        Text(
          'An archetype called “$archetypeId” would have to be added to the '
          'shared library with a purpose, its chrome, its slots, the actions '
          'it leads to and the safeguards it cannot ship without. Every area '
          'that names it would then render it, and its copy could be written '
          'per program.',
          style: TetherText.cardBody,
        ),
      ],
    );
  }
}

/// A plain white card with an uppercase eyebrow. Private to this file for the
/// same reason as its twin on the unwritten screen: the gap renderers invent
/// their own layout, and that licence should not leak into the shared widgets
/// the rest of the product is transcribed into.
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

/// A labelled fact, stacked so that neither half is squeezed at 320px.
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
