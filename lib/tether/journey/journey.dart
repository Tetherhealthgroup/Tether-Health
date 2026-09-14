/// Builds a program's screen list for any of the eleven areas.
///
/// The bundle's central claim is that the machinery is built once and then
/// shaped to each area, and `areas.json` already commits to that: every area
/// names the shared archetypes it draws on and the few it needs that the
/// library does not have. Cardiovascular lists twelve shared archetypes and
/// two specific ones; cancer lists seven and one. Nobody has to invent a
/// screen list — the catalogue is the screen list.
///
/// So a program is derivable for all eleven areas, not just the two with a
/// product file. A product file, where one exists, is richer: it pins routes,
/// delivery phases and the exact screen order a designer chose. Where one does
/// not, the area's own declaration is used and the result is honest about
/// being generated.
library;

import 'package:flutter/foundation.dart';

import '../data/design_bundle.dart';

/// Where a screen in a journey came from.
enum JourneyOrigin {
  /// Pinned by a product file: id, route, phase and order are all authored.
  product,

  /// Derived from the area's own `screens.shared` list.
  areaShared,

  /// Derived from the area's own `screens.specific` list. These are the
  /// archetypes the area needs that the shared library has not promoted.
  areaSpecific,
}

/// How complete a screen is, which is the thing a reviewer most needs to see.
enum JourneyReadiness {
  /// An archetype exists and a content pack fills its slots. This renders as
  /// the real screen.
  authored,

  /// The screen exists as approved artwork rather than as authored slots.
  ///
  /// Only BreatheFree. Its 28 screens went through review as 1290 × 2796
  /// images, which is why the bundle ships no content file for it: there are
  /// no slots to fill, because the design is the picture. Rendering those
  /// screens as unwritten stubs would have claimed a gap that does not exist,
  /// and writing copy for them would have produced a second, unreviewed
  /// version of a design that is already signed off.
  artwork,

  /// An archetype exists but nothing has written its copy. This renders as the
  /// archetype's slot list, visibly unwritten.
  awaitingCopy,

  /// The archetype itself has not been built. `age_gate`, `intercept` and
  /// `environment` are the three the bundle names as awaiting promotion, and
  /// several areas name others. This renders as a statement that it does not
  /// exist yet.
  awaitingArchetype,
}

/// One screen in one program's journey.
@immutable
class JourneyScreen {
  const JourneyScreen({
    required this.id,
    required this.archetypeId,
    required this.route,
    required this.phase,
    required this.origin,
    required this.archetype,
    required this.content,
    required this.rationale,
    required this.isShell,
    required this.isProposed,
    this.approvedScreen,
  });

  /// The approved artwork this screen was signed off as, where there is one.
  ///
  /// See [JourneyBuilder.approvedScreenFor] for why the mapping lives in this
  /// file at all.
  final int? approvedScreen;

  /// `S12`, or `tobacco.home` for a generated screen.
  final String id;

  final String archetypeId;

  /// The route this screen lives at. Authored for product screens,
  /// `/<areaId>/<archetypeId>` for generated ones.
  final String route;

  /// The delivery phase, where a product file names one. Zero otherwise.
  final int phase;

  final JourneyOrigin origin;

  /// Null when the archetype has not been built.
  final Archetype? archetype;

  /// Null when nobody has written this screen's copy.
  final ScreenContent? content;

  /// Why the area asked for this screen, where the catalogue says. Only
  /// `screens.specific` entries carry one.
  final String? rationale;

  /// Supplied by the host shell and identical in every program.
  final bool isShell;

  /// The archetype is proposed rather than promoted into the shared library.
  final bool isProposed;

  /// Content is checked before the archetype, and the order matters.
  ///
  /// LookUp's intercept is the case that settles it: `S22` has fully authored
  /// copy but its archetype is one of the three still awaiting promotion. It
  /// is a screen that can be drawn, so it is drawn. Checking the archetype
  /// first would render the most finished screen in the product as a stub.
  JourneyReadiness get readiness {
    if (content != null) return JourneyReadiness.authored;
    if (approvedScreen != null) return JourneyReadiness.artwork;
    if (archetype != null) return JourneyReadiness.awaitingCopy;
    return JourneyReadiness.awaitingArchetype;
  }

  /// Whether this screen can be shown to a person as a finished design,
  /// whether that design is authored slots or approved artwork.
  bool get isDrawable =>
      readiness == JourneyReadiness.authored ||
      readiness == JourneyReadiness.artwork;

  /// The title to show in chrome, whether or not copy exists.
  String get title =>
      content?.title.isNotEmpty == true ? content!.title : archetype?.name ?? archetypeId;
}

/// One area's program: its screens, and what is missing from them.
@immutable
class Journey {
  const Journey({
    required this.area,
    required this.product,
    required this.locale,
    required this.screens,
  });

  final Area area;

  /// Null for the nine areas that have no product file.
  final Product? product;

  final String locale;

  /// The screens, in delivery order.
  final List<JourneyScreen> screens;

  /// Whether this journey came from a product file rather than being derived
  /// from the area catalogue. Surfaced in the UI, because a generated journey
  /// is a proposal and an authored one is a decision.
  bool get isGenerated => product == null;

  /// The screen a person lands on when they open the program. The home
  /// archetype where there is one — every area in the catalogue has it — and
  /// otherwise the first screen in the journey.
  JourneyScreen? get entry {
    for (final screen in screens) {
      if (screen.archetypeId == 'home') return screen;
    }
    return screens.isEmpty ? null : screens.first;
  }

  JourneyScreen? screen(String id) {
    for (final screen in screens) {
      if (screen.id == id) return screen;
    }
    return null;
  }

  JourneyScreen? byRoute(String route) {
    for (final screen in screens) {
      if (screen.route == route) return screen;
    }
    return null;
  }

  List<JourneyScreen> withReadiness(JourneyReadiness readiness) =>
      screens.where((screen) => screen.readiness == readiness).toList();

  /// Screens whose copy is still unwritten. For LookUp this is the ten the
  /// bundle's content file does not cover; for a generated journey it is
  /// nearly all of them.
  List<JourneyScreen> get awaitingCopy =>
      withReadiness(JourneyReadiness.awaitingCopy);

  /// Screens whose archetype has not been built at all.
  List<JourneyScreen> get awaitingArchetype =>
      withReadiness(JourneyReadiness.awaitingArchetype);

  /// Every destination a screen points at that no screen in this journey
  /// supplies. The bundle's first test is "no dead ends"; this is that test,
  /// available at runtime so the coverage panel can show it.
  Set<String> get deadEnds {
    final known = {for (final screen in screens) screen.id};
    return {
      for (final screen in screens)
        ...?screen.content?.destinations.where((id) => !known.contains(id)),
    };
  }

  /// The safeguards this program is bound by: the area's, plus everything its
  /// archetypes declare they cannot ship without.
  Set<String> get safeguardIds => {
        ...area.safeguardIds,
        for (final screen in screens) ...?screen.archetype?.requires,
      };
}

/// Builds [Journey]s from a [DesignBundle].
abstract final class JourneyBuilder {
  /// The approved artwork number for a product screen, where one exists.
  ///
  /// BreatheFree's product file numbers its screens `S01`…`S28` and
  /// `assets/screens/` numbers the approved artwork `1`…`28`, and the two
  /// agree exactly: `S05` is the trigger map and `screen-05-trigger-map` is a
  /// picture of the trigger map. The product lists 23 of the 28 — it omits
  /// readiness result, guided stress reset, exercise recheck, quit-day home
  /// and the medication centre, which have no shared archetype behind them —
  /// so the map is partial in one direction only, and a number outside the
  /// artwork's range yields null rather than a broken asset path.
  ///
  /// The bundle has no field for "this screen is approved artwork", so the
  /// knowledge has to live somewhere. It lives next to the screen list it
  /// applies to rather than in a renderer, because it is a fact about the
  /// product, not about how a widget draws.
  static int? approvedScreenFor(String productId, String screenId) {
    if (productId != 'breathefree') return null;
    final match = RegExp(r'^S(\d{2})$').firstMatch(screenId);
    if (match == null) return null;
    final number = int.parse(match.group(1)!);
    return number >= 1 && number <= approvedScreenCount ? number : null;
  }

  /// How many approved screens `assets/screens/` holds.
  static const approvedScreenCount = 28;

  /// The order the shared library lists its archetypes in.
  ///
  /// A generated journey follows it rather than the order the area happens to
  /// list them, so that welcome comes before consent and rescue comes before
  /// recheck in every area without each area having to restate the sequence.
  static List<String> _canonicalOrder(DesignBundle bundle) =>
      bundle.archetypes.keys.toList(growable: false);

  /// Builds the journey for one area.
  static Journey forArea(
    DesignBundle bundle,
    Area area, {
    String locale = 'en',
  }) {
    final product = bundle.productForArea(area.id);
    if (product != null) {
      return _fromProduct(bundle, area, product, locale);
    }
    return _fromCatalogue(bundle, area, locale);
  }

  /// Every area's journey, in catalogue order.
  static List<Journey> all(DesignBundle bundle, {String locale = 'en'}) => [
        for (final area in bundle.areas) forArea(bundle, area, locale: locale),
      ];

  static Journey _fromProduct(
    DesignBundle bundle,
    Area area,
    Product product,
    String locale,
  ) {
    final content = bundle.contentFor(product.id, locale);
    final proposed = {
      for (final entry in product.proposedArchetypes) entry.id: entry.why,
    };

    return Journey(
      area: area,
      product: product,
      locale: locale,
      screens: [
        for (final screen in product.screens)
          JourneyScreen(
            id: screen.id,
            archetypeId: screen.archetypeId,
            route: screen.route,
            phase: screen.phase,
            origin: JourneyOrigin.product,
            archetype: bundle.archetypes[screen.archetypeId],
            content: content?.screen(screen.id),
            rationale: proposed[screen.archetypeId],
            isShell: screen.isShell,
            isProposed: screen.isNew,
            approvedScreen: approvedScreenFor(product.id, screen.id),
          ),
      ],
    );
  }

  /// Derives a journey from `areas.json` alone.
  ///
  /// The shell's six screens are appended to every program, because
  /// `shell.json` says they are built once and are identical everywhere. An
  /// area that never lists them still has them.
  static Journey _fromCatalogue(DesignBundle bundle, Area area, String locale) {
    final order = _canonicalOrder(bundle);
    final shellArchetypes = <String>{
      for (final screen in bundle.shell.screens) _shellArchetypeId(screen.id),
    };

    int rank(String archetypeId) {
      final index = order.indexOf(archetypeId);
      // An archetype the library does not define sorts last: it is a gap, and
      // a gap does not belong in the middle of a flow a reviewer is reading.
      return index == -1 ? order.length : index;
    }

    final shared = area.sharedArchetypeIds
        .where((id) => !shellArchetypes.contains(id))
        .toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));

    final screens = <JourneyScreen>[
      for (final archetypeId in shared)
        JourneyScreen(
          id: '${area.id}.$archetypeId',
          archetypeId: archetypeId,
          route: '/${area.id}/$archetypeId',
          phase: 0,
          origin: JourneyOrigin.areaShared,
          archetype: bundle.archetypes[archetypeId],
          content: null,
          rationale: null,
          isShell: false,
          isProposed: false,
        ),
      for (final proposed in area.specificArchetypes)
        JourneyScreen(
          id: '${area.id}.${proposed.id}',
          archetypeId: proposed.id,
          route: '/${area.id}/${proposed.id}',
          phase: 0,
          origin: JourneyOrigin.areaSpecific,
          archetype: bundle.archetypes[proposed.id],
          content: null,
          rationale: proposed.why,
          isShell: false,
          isProposed: true,
        ),
      for (final screen in bundle.shell.screens)
        JourneyScreen(
          id: '${area.id}.${screen.id}',
          archetypeId: _shellArchetypeId(screen.id),
          route: '/${area.id}/${screen.id.toLowerCase()}',
          phase: 0,
          origin: JourneyOrigin.areaShared,
          archetype: bundle.archetypes[_shellArchetypeId(screen.id)],
          content: null,
          rationale: screen.purpose,
          isShell: true,
          isProposed: false,
        ),
    ];

    return Journey(
      area: area,
      product: null,
      locale: locale,
      screens: screens,
    );
  }

  /// Maps a shell screen id to the archetype that draws it.
  ///
  /// `shell.json` and `archetypes.json` describe the same six screens under
  /// different names — SH1 is `programs_home`, SH6 is `crisis_route` — because
  /// one file is the shell's contract and the other is the drawing library.
  /// This is the single place the two vocabularies meet.
  static String _shellArchetypeId(String shellScreenId) {
    return switch (shellScreenId) {
      'SH1' => 'programs_home',
      'SH2' => 'area_directory',
      'SH3' => 'program_join',
      'SH4' => 'record',
      'SH5' => 'sharing_matrix',
      'SH6' => 'crisis_route',
      _ => shellScreenId,
    };
  }
}
