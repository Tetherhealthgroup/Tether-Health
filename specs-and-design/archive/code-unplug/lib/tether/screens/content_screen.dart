import 'package:flutter/material.dart';

import '../data/design_bundle.dart';
import '../journey/journey.dart';
import '../theme/tether_tokens.dart';
import '../widgets/blocks/block_view.dart';
import '../widgets/tether_page.dart';
import 'unwritten_screen.dart';

/// A screen that has the words to draw.
///
/// This is the only one of the three renderers that draws the product as a
/// person would see it, and it is also the rarest: of the eleven areas exactly
/// one has a content file, and inside that one, twenty-four of the product's
/// thirty-four screens are written. Everything else in the app renders through
/// [UnwrittenScreen] or `UnbuiltScreen`.
///
/// Note what is *not* required here. [JourneyScreen.readiness] checks content
/// before archetype, so a screen can reach this renderer with no archetype at
/// all — LookUp's intercept, `S22`, is exactly that: finished copy sitting on
/// one of the three archetypes still awaiting promotion. Nothing below touches
/// [JourneyScreen.archetype]. The screen's own `ScreenContent` carries the
/// chrome — title, badge, progress, leading, dark — that an unwritten screen
/// has to borrow from its archetype, so drawing from anywhere else would turn
/// the most finished screen in the product into a stub.
///
/// There is deliberately no interpretation of the content beyond mapping fields
/// onto [TetherPage]. The bundle's README calls the JSON the asset and the
/// prototype disposable, so a renderer that quietly improved a headline, or
/// supplied a default where the file had none, would be editing the asset from
/// the wrong end. Whatever `content.lookup.en.json` says is what is drawn.
class ContentScreen extends StatelessWidget {
  const ContentScreen({
    required this.screen,
    required this.journey,
    required this.onNavigate,
    super.key,
  });

  final JourneyScreen screen;

  /// The program this screen belongs to. Needed only to answer one question —
  /// does an action's destination exist? — but that question is the whole of
  /// the bundle's first acceptance test, so the journey has to be in hand.
  final Journey journey;

  /// Called with a screen id (`S12`, `SH6`), never a route. Content addresses
  /// other screens by id, so resolving an id to a page is the host's job and
  /// not this widget's; pushing a route from here would hard-code one
  /// navigation model into every screen in the product.
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final content = screen.content;
    if (content == null) {
      // `JourneyScreenHost` switches on readiness and never routes an unwritten
      // screen here, so this is a caller that bypassed the host. Degrade to the
      // renderer that can still say something true about the screen rather than
      // throwing: a reviewer losing a page is worse than a reviewer seeing the
      // slot list twice.
      assert(
        false,
        'ContentScreen was given ${screen.id}, which has no authored content. '
        'Use JourneyScreenHost, which routes by readiness.',
      );
      return UnwrittenScreen(
        screen: screen,
        journey: journey,
        onNavigate: onNavigate,
      );
    }

    return TetherPage(
      title: content.title,
      badge: content.badge,
      progress: content.progress,
      leading: content.leading,
      dark: content.dark,
      headline: content.headline,
      sub: content.sub,
      body: [
        // Words written in this repository are marked on every screen that
        // carries them, every time it is shown. Not once at first run, not in
        // a settings page, not in the README — on the screen, above the
        // content, where somebody reading it cannot miss it.
        //
        // Ten of LookUp's thirty-four screens were written here to close the
        // gap the bundle left. They are in the bundle's voice and they avoid
        // anything that reads as clinical advice, but nobody has reviewed
        // them, and a health product that cannot tell a reader which of its
        // sentences were signed off is worse than one that is visibly
        // incomplete.
        if (content.provenance == ContentProvenance.supplement)
          const _UnreviewedNotice(),
        // The index is passed down rather than derived inside the block,
        // because `TetherSession` keys a person's answers by block index within
        // the screen. A block that did not know its own position could not read
        // back what was typed into it.
        //
        // The area goes with it for the same reason one level up: the answer
        // key is the pair, not the screen. `behavioral` and `digital` both run
        // LookUp and therefore both contain this very screen id, so a block
        // told only `S13` would write into whichever of the two programs
        // happened to have written there first. The journey knows which one
        // this is; the block cannot.
        for (final (index, block) in content.blocks.indexed)
          BlockView(
            block: block,
            index: index,
            areaId: journey.area.id,
            screenId: screen.id,
            onNavigate: onNavigate,
            dark: content.dark,
          ),
      ],
      actions: [
        for (final action in content.actions)
          TetherActionButton(
            label: action.label,
            kind: action.kind,
            dark: content.dark,
            // A button whose destination is not in this journey is rendered
            // dead rather than live. The bundle's first acceptance test is "no
            // dead ends", and the honest way to fail a test is visibly: a
            // disabled button tells a reviewer the target screen is missing,
            // whereas a live one that no-ops on tap tells them the app is
            // broken. `Journey.deadEnds` counts exactly these, and the coverage
            // panel lists them, so the two surfaces agree by construction.
            //
            // This is not a branch that never runs. LookUp's authored content
            // resolves every one of its targets, but a journey derived from the
            // area catalogue carries only the archetypes that area named, and
            // an authored screen borrowed into it can point somewhere the
            // generated screen list does not go.
            //
            // An action with an empty `to` — which the parser produces for a
            // content file mid-edit — falls into the same branch, because
            // `Journey.screen('')` finds nothing.
            onPressed: journey.screen(action.to) == null
                ? null
                : () => onNavigate(action.to),
          ),
      ],
      footer: content.footer,
    );
  }
}

/// Says, on the screen, that these words have not been reviewed.
///
/// Coral rather than a neutral grey, and above the content rather than in the
/// footer, because this is the one notice on the screen that changes how
/// everything below it should be read.
class _UnreviewedNotice extends StatelessWidget {
  const _UnreviewedNotice();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
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
            Text('NOT CLINICALLY REVIEWED', style: TetherText.eyebrow),
            SizedBox(height: 4),
            Text(
              'This screen was written to fill a gap in the design bundle. '
              'Nobody has reviewed it.',
              style: TetherText.cardBody,
            ),
          ],
        ),
      ),
    );
  }
}
