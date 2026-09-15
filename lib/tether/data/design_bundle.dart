/// The design bundle, parsed.
///
/// `files/tether-design.zip` ships the product as data in three deliberately
/// separate layers — the area catalogue, the shared archetype machinery, and
/// thin per-product files — plus safeguards that are constraints rather than
/// features. Its README is blunt about which artefact is the asset: *the
/// prototype is disposable; the JSON is the asset.*
///
/// So this app renders the JSON rather than transcribing it into Dart. The
/// alternative — hand-writing thirty-four screens per product across eleven
/// areas — is the twenty-eight-hand-written-specs-per-product problem the
/// bundle exists to avoid, and it would drift from the JSON the first time
/// somebody edited one and not the other.
///
/// Every model here is immutable and parses defensively: a missing optional
/// key yields null, never a crash, because a content file that is mid-edit
/// should degrade to a visibly incomplete screen rather than a black one.
library;

import 'package:flutter/foundation.dart';

/// Where a piece of the design came from.
///
/// The shipped bundle and anything written in this repository are kept
/// distinguishable for the whole life of the data, because they carry
/// different authority. A screen from `tether-design.zip` went through the
/// bundle's own review; a screen authored here to fill a gap has been through
/// nobody's. Collapsing the two would mean unreviewed wording appearing in a
/// health product indistinguishable from wording that was signed off, which is
/// the single worst outcome available in this codebase.
///
/// Anything [ContentProvenance.supplement] renders with a visible notice. See
/// `lib/tether/screens/content_screen.dart`.
enum ContentProvenance {
  /// From `files/tether-design.zip`, copied verbatim into `assets/design/`.
  bundle,

  /// Authored in this repository to fill a gap. Not clinically reviewed.
  supplement,
}

// ---------------------------------------------------------------------------
// Areas — data/areas.json
// ---------------------------------------------------------------------------

/// How far an area has actually got.
///
/// The distinction is load-bearing, not decorative: `shell.json` forbids the
/// home screen from listing areas at all, and the area directory is required
/// to be "honest about status". A planned area has no implementation, and the
/// UI is required to say so rather than imply a program a person could join.
enum AreaStatus {
  inDevelopment('in_development', 'In development'),
  design('design', 'Design'),
  planned('planned', 'Planned');

  const AreaStatus(this.wire, this.label);

  /// The value as it appears in `areas.json`.
  final String wire;

  /// The label shown in the area directory.
  final String label;

  static AreaStatus parse(Object? value) {
    return AreaStatus.values.firstWhere(
      (status) => status.wire == value,
      // An unrecognised status is treated as the least advanced one. Guessing
      // upward would advertise something that does not exist.
      orElse: () => AreaStatus.planned,
    );
  }
}

/// One of the forty-one service lines inside an area.
@immutable
class ServiceLine {
  const ServiceLine({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  factory ServiceLine.fromJson(Map<String, Object?> json) {
    return ServiceLine(
      id: json['id']! as String,
      name: json['name']! as String,
      description: (json['description'] as String?) ?? '',
    );
  }
}

/// Something an area measures.
@immutable
class Measure {
  const Measure({
    required this.id,
    required this.label,
    required this.unit,
    required this.selfReported,
    required this.derived,
    required this.estimate,
    required this.clinicalThresholds,
    required this.neverDiagnostic,
    required this.platformDependent,
  });

  final String id;
  final String label;
  final String unit;

  /// The person said it; nothing measured it.
  final bool selfReported;

  /// Computed from other measures rather than collected.
  final bool derived;

  /// Approximate by nature, and must not be presented as exact.
  final bool estimate;

  /// Values here can be dangerous, which drags the whole binary toward medical
  /// device territory. `shell.json`'s `threshold_areas_separable` rule requires
  /// any area carrying one of these to be removable behind a feature flag.
  final bool clinicalThresholds;

  /// The measure may prompt somebody to seek help and may never be shown as a
  /// condition.
  final bool neverDiagnostic;

  /// The platform decides whether this can be collected at all. iOS returns
  /// aggregate screen time only, so a per-app number has to degrade rather
  /// than show a plausible-looking zero.
  final bool platformDependent;

  factory Measure.fromJson(Map<String, Object?> json) {
    bool flag(String key) => json[key] == true;
    return Measure(
      id: json['id']! as String,
      label: json['label']! as String,
      unit: (json['unit'] as String?) ?? '',
      selfReported: flag('selfReported'),
      derived: flag('derived'),
      estimate: flag('estimate'),
      clinicalThresholds: flag('clinicalThresholds'),
      neverDiagnostic: flag('neverDiagnostic'),
      platformDependent: flag('platformDependent'),
    );
  }
}

/// An archetype an area needs that the shared library does not yet have.
@immutable
class ProposedArchetype {
  const ProposedArchetype({required this.id, required this.why});

  final String id;

  /// Why it is needed, and — per the bundle's own rule for adding an area —
  /// which other areas could reuse it. That second half is the test that stops
  /// the shared library fragmenting into eleven bespoke products.
  final String why;

  factory ProposedArchetype.fromJson(Map<String, Object?> json) {
    return ProposedArchetype(
      id: json['id']! as String,
      why: (json['why'] ?? json['reason'] ?? '') as String,
    );
  }
}

/// One of the eleven health areas.
@immutable
class Area {
  const Area({
    required this.id,
    required this.name,
    required this.scope,
    required this.status,
    required this.url,
    required this.productId,
    required this.serviceLines,
    required this.measures,
    required this.safeguardIds,
    required this.sharedArchetypeIds,
    required this.specificArchetypes,
  });

  final String id;
  final String name;

  /// The conditions the area covers, in the words the website uses.
  final String scope;

  final AreaStatus status;

  /// The public page for this area on tetherhealthgroup.com.
  final String url;

  /// The product that implements the area, when one exists. Null for the nine
  /// areas that are a plan rather than an implementation.
  final String? productId;

  final List<ServiceLine> serviceLines;
  final List<Measure> measures;

  /// Ids into [Safeguard]. Resolved by [DesignBundle.safeguardsFor].
  final List<String> safeguardIds;

  /// Ids of shared archetypes this area draws on, in the order the bundle
  /// lists them. This is what makes a program buildable without a product
  /// file: the area already declares its own screen list.
  final List<String> sharedArchetypeIds;

  /// Archetypes this area needs that the shared library does not have.
  final List<ProposedArchetype> specificArchetypes;

  /// Whether this area carries a measure that could push the app toward a
  /// regulated classification. See [Measure.clinicalThresholds].
  bool get hasClinicalThresholds =>
      measures.any((measure) => measure.clinicalThresholds);

  /// The same area with a product bound to it, and its status corrected.
  ///
  /// The only override the supplement may make to the catalogue, and it is
  /// narrow on purpose: `productId` and `status` and nothing else. A name, a
  /// scope or a service line is a statement about what the organisation does
  /// and belongs to whoever maintains `areas.json`.
  ///
  /// `status` has to move with `productId` or the app contradicts itself. An
  /// area labelled `planned` while offering a programme somebody can join is
  /// the exact dishonesty the area directory exists to prevent — it is the
  /// screen whose whole contract is being truthful about what exists.
  Area withImplementation({required String productId, AreaStatus? status}) {
    return Area(
      id: id,
      name: name,
      scope: scope,
      status: status ?? this.status,
      url: url,
      productId: productId,
      serviceLines: serviceLines,
      measures: measures,
      safeguardIds: safeguardIds,
      sharedArchetypeIds: sharedArchetypeIds,
      specificArchetypes: specificArchetypes,
    );
  }

  factory Area.fromJson(Map<String, Object?> json) {
    final screens = (json['screens'] as Map<String, Object?>?) ?? const {};
    return Area(
      id: json['id']! as String,
      name: json['name']! as String,
      scope: (json['scope'] as String?) ?? '',
      status: AreaStatus.parse(json['status']),
      url: (json['url'] as String?) ?? '',
      productId: json['productId'] as String?,
      serviceLines: _list(json['serviceLines'], ServiceLine.fromJson),
      measures: _list(json['measures'], Measure.fromJson),
      safeguardIds: _strings(json['safeguards']),
      sharedArchetypeIds: _strings(screens['shared']),
      specificArchetypes:
          _list(screens['specific'], ProposedArchetype.fromJson),
    );
  }
}

// ---------------------------------------------------------------------------
// Archetypes — data/archetypes.json
// ---------------------------------------------------------------------------

/// What the top bar of a screen carries.
@immutable
class ArchetypeChrome {
  const ArchetypeChrome({
    required this.leading,
    required this.badge,
    required this.progress,
  });

  /// `none`, `back` or `close`.
  final String leading;

  /// Whether the screen shows a status pill beside its title.
  final bool badge;

  /// Whether the screen shows a progress hairline under the bar.
  final bool progress;

  factory ArchetypeChrome.fromJson(Map<String, Object?>? json) {
    return ArchetypeChrome(
      // `prototype.py` defaults an absent lead to `close`; matching that here
      // keeps the app and the reference renderer in step.
      leading: (json?['leading'] as String?) ?? 'close',
      badge: json?['badge'] == true,
      progress: json?['progress'] == true,
    );
  }
}

/// An action an archetype declares, before content supplies its label.
@immutable
class ArchetypeAction {
  const ArchetypeAction({required this.kind, required this.to});

  /// `primary`, `ghost` or `lime`.
  final String kind;

  /// The archetype id this action leads to.
  final String to;

  factory ArchetypeAction.fromJson(Map<String, Object?> json) {
    return ArchetypeAction(
      kind: (json['kind'] as String?) ?? 'primary',
      to: (json['to'] as String?) ?? '',
    );
  }
}

/// One of the shared screen archetypes.
///
/// This is the layer the bundle says pays for itself: improve the lapse screen
/// once and every area with lapses inherits it.
@immutable
class Archetype {
  const Archetype({
    required this.id,
    required this.name,
    required this.purpose,
    required this.chrome,
    required this.slots,
    required this.actions,
    required this.requires,
    required this.notes,
    this.provenance = ContentProvenance.bundle,
  });

  /// Whether the shared library defines this archetype, or this repository
  /// proposed it. See [ContentProvenance].
  final ContentProvenance provenance;

  final String id;
  final String name;
  final String purpose;
  final ArchetypeChrome chrome;

  /// Slot name to its cardinality spec, such as `required`, `optional`,
  /// `required:3` or `required:0-2`. Kept as the raw string because the spec
  /// is shown to a reviewer verbatim on an unwritten screen.
  final Map<String, String> slots;

  final List<ArchetypeAction> actions;

  /// What this archetype cannot ship without.
  ///
  /// The tokens are of two kinds and the bundle does not separate them. Six of
  /// the fourteen are safeguard ids — `slip_never_resets`, `never_prescribe`.
  /// The rest are capabilities: three are named inside a safeguard's own
  /// `requires` list (`crisis_card_pinned_first`, `self_report_disclaimer`,
  /// `share_preview`) and five stand alone (`offline_capable`, `no_data_sent`,
  /// `reduced_motion_fallback`, `product_disclaimer`, `review_date`).
  ///
  /// Both kinds are binding. Use [DesignBundle.safeguardsRequiredBy] and
  /// [DesignBundle.capabilitiesRequiredBy] to tell them apart rather than
  /// assuming every entry resolves to a [Safeguard] — it does not, and code
  /// that assumes it does quietly drops `offline_capable` from the rescue
  /// screen, which is the one requirement on it that matters at 11pm with no
  /// signal.
  final List<String> requires;

  /// The design note, where the bundle left one. These are the sentences that
  /// explain why a screen is shaped the way it is — "the skip must exist", "one
  /// action, never a list of five" — and they are worth surfacing to a
  /// reviewer rather than burying in a file nobody rereads.
  final String? notes;

  /// Slots that must be filled for the screen to be complete.
  Iterable<String> get requiredSlots => slots.entries
      .where((entry) => entry.value.startsWith('required'))
      .map((entry) => entry.key);

  factory Archetype.fromJson(
    Map<String, Object?> json, {
    ContentProvenance provenance = ContentProvenance.bundle,
  }) {
    final slots = (json['slots'] as Map<String, Object?>?) ?? const {};
    return Archetype(
      provenance: provenance,
      id: json['id']! as String,
      name: (json['name'] as String?) ?? (json['id']! as String),
      purpose: (json['purpose'] as String?) ?? '',
      chrome: ArchetypeChrome.fromJson(json['chrome'] as Map<String, Object?>?),
      slots: {
        for (final entry in slots.entries) entry.key: '${entry.value}',
      },
      actions: _list(json['actions'], ArchetypeAction.fromJson),
      requires: _strings(json['requires']),
      notes: json['notes'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Safeguards — data/safeguards.json
// ---------------------------------------------------------------------------

/// A constraint a product cannot ship a screen in violation of.
///
/// The bundle is explicit that these are "the rules most likely to be quietly
/// violated by someone shipping fast, so they are machine-checkable rather
/// than living in a document nobody rereads". `test/tether_safeguards_test.dart`
/// is where that check lives in this app.
@immutable
class Safeguard {
  const Safeguard({
    required this.id,
    required this.name,
    required this.statement,
    required this.requires,
    required this.forbids,
    required this.defaultOff,
  });

  final String id;
  final String name;
  final String statement;

  /// Capabilities a screen must carry to satisfy this safeguard.
  final List<String> requires;

  /// Capabilities a screen may not carry.
  final List<String> forbids;

  /// Whether the behaviour this safeguard governs ships switched off.
  final bool defaultOff;

  factory Safeguard.fromJson(Map<String, Object?> json) {
    return Safeguard(
      id: json['id']! as String,
      name: (json['name'] as String?) ?? (json['id']! as String),
      statement: (json['statement'] as String?) ?? '',
      requires: _strings(json['requires']),
      forbids: _strings(json['forbids']),
      defaultOff: json['defaultOff'] == true,
    );
  }
}

// ---------------------------------------------------------------------------
// Shell — data/shell.json
// ---------------------------------------------------------------------------

/// A rule the host shell obeys in every area.
@immutable
class ShellRule {
  const ShellRule({
    required this.id,
    required this.rule,
    required this.why,
    required this.examples,
  });

  final String id;
  final String rule;

  /// The reasoning. Shown to reviewers, and the reason these rules survive
  /// contact with a deadline.
  final String why;

  final List<String> examples;

  factory ShellRule.fromJson(Map<String, Object?> json) {
    return ShellRule(
      id: json['id']! as String,
      rule: (json['rule'] as String?) ?? '',
      why: (json['why'] as String?) ?? '',
      examples: _strings(json['examples']),
    );
  }
}

/// One of the six shell screens, SH1 to SH6.
@immutable
class ShellScreen {
  const ShellScreen({
    required this.id,
    required this.name,
    required this.purpose,
    required this.slots,
    required this.requires,
  });

  final String id;
  final String name;
  final String purpose;
  final Map<String, String> slots;
  final List<String> requires;

  factory ShellScreen.fromJson(Map<String, Object?> json) {
    final slots = (json['slots'] as Map<String, Object?>?) ?? const {};
    return ShellScreen(
      id: json['id']! as String,
      name: (json['name'] as String?) ?? (json['id']! as String),
      purpose: (json['purpose'] as String?) ?? '',
      slots: {for (final entry in slots.entries) entry.key: '${entry.value}'},
      requires: _strings(json['requires']),
    );
  }
}

/// The host shell: the part built once and identical in every area.
@immutable
class ShellSpec {
  const ShellSpec({
    required this.version,
    required this.rules,
    required this.screens,
  });

  final String version;
  final List<ShellRule> rules;
  final List<ShellScreen> screens;

  ShellRule? rule(String id) {
    for (final rule in rules) {
      if (rule.id == id) return rule;
    }
    return null;
  }

  /// The ceiling from the `two_active_max` rule, read from the SH1 slot spec
  /// (`activeCards: "required:0-2"`) rather than hard-coded, so that changing
  /// the JSON changes the app.
  int get maxActivePrograms {
    for (final screen in screens) {
      if (screen.id != 'SH1') continue;
      final spec = screen.slots['activeCards'];
      final match = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(spec ?? '');
      if (match != null) return int.parse(match.group(2)!);
    }
    return 2;
  }

  factory ShellSpec.fromJson(Map<String, Object?> json) {
    return ShellSpec(
      version: (json['version'] as String?) ?? '0.0.0',
      rules: _list(json['rules'], ShellRule.fromJson),
      screens: _list(json['screens'], ShellScreen.fromJson),
    );
  }
}

// ---------------------------------------------------------------------------
// Products — data/products/*.json
// ---------------------------------------------------------------------------

/// One screen in a product's journey.
@immutable
class ProductScreen {
  const ProductScreen({
    required this.id,
    required this.archetypeId,
    required this.route,
    required this.phase,
    required this.isNew,
    required this.isShell,
  });

  /// `S01`…`S28`, or `SH1`…`SH6`.
  final String id;

  final String archetypeId;

  /// The route this screen lives at, such as `/today`.
  final String route;

  /// The delivery phase, 1 to 8.
  final int phase;

  /// Marked `$new` in the product file: the archetype is proposed, not yet
  /// promoted into the shared library.
  final bool isNew;

  /// Marked `$shell`: supplied by the host shell, identical in every program.
  final bool isShell;

  factory ProductScreen.fromJson(Map<String, Object?> json) {
    return ProductScreen(
      id: json['id']! as String,
      archetypeId: json['archetype']! as String,
      route: (json['route'] as String?) ?? '',
      phase: (json['phase'] as num?)?.toInt() ?? 0,
      isNew: json[r'$new'] == true,
      isShell: json[r'$shell'] == true,
    );
  }
}

/// A crisis or support number, per locale.
@immutable
class Helpline {
  const Helpline({
    required this.locale,
    required this.name,
    required this.number,
  });

  final String locale;
  final String name;
  final String number;

  factory Helpline.fromJson(Map<String, Object?> json) {
    return Helpline(
      locale: (json['locale'] as String?) ?? 'en',
      name: json['name']! as String,
      number: (json['number'] as String?) ?? '',
    );
  }
}

/// A product: an area, a vocabulary, a screen list and its helplines.
///
/// Thin on purpose. Most of a product's design lives in the archetypes it
/// borrows.
@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.areaId,
    required this.serviceLineIds,
    required this.status,
    required this.locales,
    required this.vocabulary,
    required this.helplines,
    required this.screens,
    required this.platformCapabilities,
    required this.proposedArchetypes,
  });

  final String id;

  /// The product's name. Both current names are flagged in the bundle as
  /// placeholders that are not trademark-cleared.
  final String name;

  final String areaId;
  final List<String> serviceLineIds;
  final String status;
  final List<String> locales;

  /// The words this product uses for the shared concepts — LookUp's urge is a
  /// "pull", its lapse is "going over". An archetype is generic; the words a
  /// person reads are not.
  final Map<String, String> vocabulary;

  final List<Helpline> helplines;
  final List<ProductScreen> screens;

  /// What the platform can actually do for this product.
  final Map<String, Object?> platformCapabilities;

  final List<ProposedArchetype> proposedArchetypes;

  ProductScreen? screen(String id) {
    for (final screen in screens) {
      if (screen.id == id) return screen;
    }
    return null;
  }

  /// The word this product uses for [concept], or [concept] itself when the
  /// product has not renamed it.
  String word(String concept) => vocabulary[concept] ?? concept;

  List<Helpline> helplinesFor(String locale) =>
      helplines.where((line) => line.locale == locale).toList(growable: false);

  factory Product.fromJson(Map<String, Object?> json) {
    final vocabulary =
        (json['vocabulary'] as Map<String, Object?>?) ?? const {};
    return Product(
      id: json['id']! as String,
      name: (json['name'] as String?) ?? (json['id']! as String),
      areaId: (json['areaId'] as String?) ?? '',
      serviceLineIds: _strings(json['serviceLines']),
      status: (json['status'] as String?) ?? 'design',
      locales: _strings(json['locales']),
      vocabulary: {
        for (final entry in vocabulary.entries) entry.key: '${entry.value}',
      },
      helplines: _list(json['helplines'], Helpline.fromJson),
      screens: _list(json['screens'], ProductScreen.fromJson),
      platformCapabilities:
          (json['platformCapabilities'] as Map<String, Object?>?) ?? const {},
      proposedArchetypes:
          _list(json['proposedArchetypes'], ProposedArchetype.fromJson),
    );
  }
}

// ---------------------------------------------------------------------------
// Content — data/content/<product>.<locale>.json
// ---------------------------------------------------------------------------

/// The tone a card is drawn in.
enum CardTone {
  plain(''),
  mint('mint'),
  mintPale('mintPale'),
  coral('coral'),
  ink('ink'),
  inkSoft('inkSoft');

  const CardTone(this.wire);

  final String wire;

  /// Whether this tone draws white text on a dark fill.
  bool get isDark => this == CardTone.ink || this == CardTone.inkSoft;

  static CardTone parse(Object? value) {
    return CardTone.values.firstWhere(
      (tone) => tone.wire == value,
      orElse: () => CardTone.plain,
    );
  }
}

/// One block of content on a screen.
///
/// The set is closed: it is exactly the ten `t` values `tools/prototype.py`
/// knows how to draw. A sealed hierarchy means adding an eleventh is a
/// compile error at every switch rather than a silently blank area of screen.
sealed class ContentBlock {
  const ContentBlock();

  /// The screen id this block navigates to when tapped, if any.
  String? get to => null;

  static ContentBlock fromJson(Map<String, Object?> json) {
    return switch (json['t']) {
      'chips' => ChipsBlock.fromJson(json),
      'options' => OptionsBlock.fromJson(json),
      'stats' => StatsBlock.fromJson(json),
      'metric' => MetricBlock.fromJson(json),
      'bars' => BarsBlock.fromJson(json),
      'slider' => SliderBlock.fromJson(json),
      'rows' => RowsBlock.fromJson(json),
      'timer' => TimerBlock.fromJson(json),
      'input' => InputBlock.fromJson(json),
      // `prototype.py` treats an absent or unknown `t` as a card.
      _ => CardBlock.fromJson(json),
    };
  }
}

/// A card. The workhorse: it carries an eyebrow, a title, a body, a pill and
/// its own chip row, in any combination.
@immutable
final class CardBlock extends ContentBlock {
  const CardBlock({
    required this.tone,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.pill,
    required this.chips,
    required this.selected,
    required this.to,
  });

  final CardTone tone;
  final String? eyebrow;
  final String? title;
  final String? body;

  /// A single pill, drawn as a selected chip. It reads as the card's action.
  final String? pill;

  final List<String> chips;

  /// Indices into [chips] that start selected.
  final Set<int> selected;

  @override
  final String? to;

  factory CardBlock.fromJson(Map<String, Object?> json) {
    return CardBlock(
      tone: CardTone.parse(json['tone']),
      eyebrow: json['eyebrow'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      pill: json['pill'] as String?,
      chips: _strings(json['chips']),
      selected: _indices(json['selected']),
      to: json['to'] as String?,
    );
  }
}

/// A bare row of chips in a plain card.
@immutable
final class ChipsBlock extends ContentBlock {
  const ChipsBlock({required this.items, required this.selected});

  final List<String> items;
  final Set<int> selected;

  factory ChipsBlock.fromJson(Map<String, Object?> json) {
    return ChipsBlock(
      items: _strings(json['items']),
      selected: _indices(json['selected']),
    );
  }
}

/// One choice inside an [OptionsBlock].
@immutable
class ContentOption {
  const ContentOption({
    required this.title,
    required this.body,
    required this.selected,
  });

  final String title;
  final String? body;
  final bool selected;

  factory ContentOption.fromJson(Map<String, Object?> json) {
    return ContentOption(
      title: (json['title'] as String?) ?? '',
      body: json['body'] as String?,
      selected: json['sel'] == true,
    );
  }
}

/// A single-select list. Picking one clears the rest.
@immutable
final class OptionsBlock extends ContentBlock {
  const OptionsBlock({required this.items});

  final List<ContentOption> items;

  factory OptionsBlock.fromJson(Map<String, Object?> json) {
    return OptionsBlock(items: _list(json['items'], ContentOption.fromJson));
  }
}

/// Two side-by-side figures.
@immutable
final class StatsBlock extends ContentBlock {
  const StatsBlock({required this.items});

  /// Value and label, in that order, as the JSON pairs them.
  final List<(String value, String label)> items;

  factory StatsBlock.fromJson(Map<String, Object?> json) {
    return StatsBlock(items: _pairs(json['items']));
  }
}

/// The dark card carrying a screen's one primary number.
@immutable
final class MetricBlock extends ContentBlock {
  const MetricBlock({
    required this.eyebrow,
    required this.value,
    required this.unit,
    required this.percent,
    required this.foot,
  });

  final String? eyebrow;
  final String value;
  final String? unit;

  /// How full the track is drawn, 0 to 100.
  final double percent;

  final String? foot;

  factory MetricBlock.fromJson(Map<String, Object?> json) {
    return MetricBlock(
      eyebrow: json['eyebrow'] as String?,
      value: '${json['value'] ?? ''}',
      unit: json['unit'] as String?,
      percent: ((json['pct'] as num?) ?? 50).toDouble().clamp(0, 100),
      foot: json['foot'] as String?,
    );
  }
}

/// A week of bars. A zero is a day that has not happened yet, and is drawn
/// flat and unfilled rather than as a day with no usage.
@immutable
final class BarsBlock extends ContentBlock {
  const BarsBlock({required this.values});

  final List<int> values;

  factory BarsBlock.fromJson(Map<String, Object?> json) {
    final raw = json['values'];
    return BarsBlock(
      values: raw is List
          ? raw.map((value) => ((value as num?) ?? 0).toInt()).toList()
          : const <int>[],
    );
  }
}

/// A 0-to-100 slider with three labels beneath it.
@immutable
final class SliderBlock extends ContentBlock {
  const SliderBlock({
    required this.title,
    required this.body,
    required this.value,
    required this.left,
    required this.mid,
    required this.right,
    required this.foot,
  });

  final String? title;
  final String? body;

  /// The starting position, 0 to 100.
  final double value;

  final String left;

  /// The current reading, in words. Drawn bold and in ink because it is the
  /// only one of the three labels that describes where the handle actually is.
  final String mid;

  final String right;

  /// A line under the control, used on the recheck screen to state where the
  /// person started.
  final String? foot;

  factory SliderBlock.fromJson(Map<String, Object?> json) {
    return SliderBlock(
      title: json['title'] as String?,
      body: json['body'] as String?,
      value: ((json['value'] as num?) ?? 50).toDouble().clamp(0, 100),
      left: (json['left'] as String?) ?? '',
      mid: (json['mid'] as String?) ?? '',
      right: (json['right'] as String?) ?? '',
      foot: json['foot'] as String?,
    );
  }
}

/// A list of key-and-value rows.
@immutable
final class RowsBlock extends ContentBlock {
  const RowsBlock({required this.items});

  final List<(String key, String value)> items;

  factory RowsBlock.fromJson(Map<String, Object?> json) {
    return RowsBlock(items: _pairs(json['items']));
  }
}

/// A countdown. The eight-second one on the intercept and the ninety-second
/// one in a rescue are the same block with a different number.
@immutable
final class TimerBlock extends ContentBlock {
  const TimerBlock({
    required this.seconds,
    required this.label,
    required this.quote,
  });

  final int seconds;

  /// The uppercase label above the ring.
  final String label;

  /// The person's own words, shown under the ring. This is the anchor the
  /// rescue archetype calls for: their reasons, surfaced at the hardest moment.
  final String? quote;

  factory TimerBlock.fromJson(Map<String, Object?> json) {
    return TimerBlock(
      seconds: ((json['seconds'] as num?) ?? 90).toInt(),
      label: (json['label'] as String?) ?? '',
      quote: json['quote'] as String?,
    );
  }
}

/// A free-text field.
///
/// The `plan_reasons` archetype notes that under-13 profiles have no free
/// text and must render chips only; enforcing that is the screen's job, not
/// this model's.
@immutable
final class InputBlock extends ContentBlock {
  const InputBlock({required this.title, required this.value});

  final String? title;

  /// The prefilled text. In the shipped content this is an example answer,
  /// which is why it is editable rather than a hint.
  final String value;

  factory InputBlock.fromJson(Map<String, Object?> json) {
    return InputBlock(
      title: json['title'] as String?,
      value: (json['value'] as String?) ?? '',
    );
  }
}

/// What the top-left control does.
enum LeadingControl {
  /// No control. Used where there is nothing to go back to.
  none,

  /// An arrow that pops the stack.
  back,

  /// A cross that leaves the flow.
  close;

  static LeadingControl parse(Object? value) {
    return switch (value) {
      'none' => LeadingControl.none,
      'back' => LeadingControl.back,
      // `prototype.py` defaults to close.
      _ => LeadingControl.close,
    };
  }
}

/// A button at the foot of a screen.
@immutable
class ContentAction {
  const ContentAction({
    required this.label,
    required this.kind,
    required this.to,
  });

  final String label;

  /// `primary`, `ghost` or `lime`. Lime appears once, on the intercept's
  /// "do something else instead", and it is the only button in the product
  /// that is neither ink nor outline.
  final String kind;

  /// The screen id this action navigates to.
  final String to;

  factory ContentAction.fromJson(Map<String, Object?> json) {
    return ContentAction(
      label: (json['label'] as String?) ?? '',
      kind: (json['kind'] as String?) ?? 'primary',
      to: (json['to'] as String?) ?? '',
    );
  }
}

/// The authored content for one screen.
@immutable
class ScreenContent {
  const ScreenContent({
    required this.id,
    required this.title,
    required this.badge,
    required this.progress,
    required this.leading,
    required this.dark,
    required this.headline,
    required this.sub,
    required this.blocks,
    required this.actions,
    required this.footer,
    this.provenance = ContentProvenance.bundle,
  });

  /// Whether these words shipped in the design bundle or were written here.
  /// A [ContentProvenance.supplement] screen renders with a visible notice.
  final ContentProvenance provenance;

  final String id;
  final String title;

  /// The status pill beside the title.
  final String? badge;

  /// The progress hairline, 0 to 100. Null draws no hairline.
  final double? progress;

  final LeadingControl leading;

  /// Whether the screen is drawn on ink rather than cream. Only the intercept
  /// uses it: it has to read over whatever app the person was opening.
  final bool dark;

  final String? headline;
  final String? sub;
  final List<ContentBlock> blocks;
  final List<ContentAction> actions;

  /// The disclosure line under the buttons.
  final String? footer;

  /// Every screen id this screen can reach, from both its buttons and its
  /// tappable cards.
  Set<String> get destinations => {
        for (final action in actions)
          if (action.to.isNotEmpty) action.to,
        for (final block in blocks)
          if (block.to case final String target) target,
      };

  /// The same screen with different action destinations.
  ///
  /// Only [ContentPack.withActionFix] calls this. Nothing else may rewrite a
  /// screen after it is parsed — the bundle's README calls the JSON the asset,
  /// and a renderer that edited it in memory would be editing the asset from
  /// the wrong end.
  ScreenContent copyWithActions(List<ContentAction> actions) {
    return ScreenContent(
      provenance: provenance,
      id: id,
      title: title,
      badge: badge,
      progress: progress,
      leading: leading,
      dark: dark,
      headline: headline,
      sub: sub,
      blocks: blocks,
      actions: actions,
      footer: footer,
    );
  }

  factory ScreenContent.fromJson(
    String id,
    Map<String, Object?> json, {
    ContentProvenance provenance = ContentProvenance.bundle,
  }) {
    final blocks = json['blocks'];
    return ScreenContent(
      provenance: provenance,
      id: id,
      title: (json['title'] as String?) ?? '',
      badge: json['badge'] as String?,
      progress: (json['progress'] as num?)?.toDouble(),
      leading: LeadingControl.parse(json['lead']),
      dark: json['dark'] == true,
      headline: json['headline'] as String?,
      sub: json['sub'] as String?,
      blocks: blocks is List
          ? blocks
              .whereType<Map<String, Object?>>()
              .map(ContentBlock.fromJson)
              .toList(growable: false)
          : const <ContentBlock>[],
      actions: _list(json['actions'], ContentAction.fromJson),
      footer: json['footer'] as String?,
    );
  }
}

/// One product's content in one locale.
@immutable
class ContentPack {
  const ContentPack({
    required this.productId,
    required this.locale,
    required this.start,
    required this.screens,
  });

  final String productId;
  final String locale;

  /// The screen the product opens on.
  final String start;

  /// Screen id to content, in the order the file lists them.
  final Map<String, ScreenContent> screens;

  ScreenContent? screen(String id) => screens[id];

  /// The screens whose words were written in this repository rather than
  /// shipped in the bundle.
  List<ScreenContent> get unreviewed => [
        for (final screen in screens.values)
          if (screen.provenance == ContentProvenance.supplement) screen,
      ];

  /// Returns this pack with an action's destination corrected.
  ///
  /// The one kind of edit the supplement may make to a shipped screen, and it
  /// is deliberately not an override of content: the label, the blocks and the
  /// footer are untouched, and only where a button *goes* changes. See
  /// `assets/design/supplement.navigation.json`, where every fix has to name
  /// the archetype rule it restores.
  ///
  /// A fix that does not match — wrong screen, index out of range, or a `from`
  /// that is no longer what the file says — is dropped rather than applied.
  /// That is what makes it safe to leave one of these in place: the day the
  /// bundle fixes the link itself, the local fix stops doing anything instead
  /// of silently rewriting the new destination.
  ContentPack withActionFix({
    required String screenId,
    required int actionIndex,
    required String from,
    required String to,
  }) {
    final screen = screens[screenId];
    if (screen == null) return this;
    if (actionIndex < 0 || actionIndex >= screen.actions.length) return this;
    if (screen.actions[actionIndex].to != from) return this;

    final actions = [...screen.actions];
    actions[actionIndex] = ContentAction(
      label: actions[actionIndex].label,
      kind: actions[actionIndex].kind,
      to: to,
    );

    return ContentPack(
      productId: productId,
      locale: locale,
      start: start,
      screens: {
        ...screens,
        screenId: screen.copyWithActions(actions),
      },
    );
  }

  /// Returns this pack with [other]'s screens filled in behind it.
  ///
  /// Behind, not over: a supplement may only fill a gap, never replace an
  /// authored screen. If the bundle later ships copy for a screen this
  /// repository had to write, the bundle's copy wins on the next load without
  /// anybody having to remember to delete the local one.
  ContentPack fillGapsFrom(ContentPack other) {
    return ContentPack(
      productId: productId,
      locale: locale,
      start: start,
      screens: {
        ...screens,
        for (final entry in other.screens.entries)
          if (!screens.containsKey(entry.key)) entry.key: entry.value,
      },
    );
  }

  factory ContentPack.fromJson(
    Map<String, Object?> json, {
    ContentProvenance provenance = ContentProvenance.bundle,
  }) {
    final screens = (json['screens'] as Map<String, Object?>?) ?? const {};
    return ContentPack(
      productId: (json['product'] as String?) ?? '',
      locale: (json['locale'] as String?) ?? 'en',
      start: (json['start'] as String?) ?? 'S01',
      screens: {
        for (final entry in screens.entries)
          entry.key: ScreenContent.fromJson(
            entry.key,
            (entry.value as Map<String, Object?>?) ?? const {},
            provenance: provenance,
          ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// The bundle
// ---------------------------------------------------------------------------

/// Everything the design bundle ships, parsed and cross-referenced.
@immutable
class DesignBundle {
  const DesignBundle({
    required this.areas,
    required this.archetypes,
    required this.safeguards,
    required this.shell,
    required this.products,
    required this.content,
  });

  /// The eleven areas, in catalogue order.
  final List<Area> areas;

  /// Archetype id to archetype.
  final Map<String, Archetype> archetypes;

  /// Safeguard id to safeguard.
  final Map<String, Safeguard> safeguards;

  final ShellSpec shell;

  /// Product id to product.
  final Map<String, Product> products;

  /// `<productId>.<locale>` to its content pack.
  final Map<String, ContentPack> content;

  Area? area(String id) {
    for (final area in areas) {
      if (area.id == id) return area;
    }
    return null;
  }

  /// The area a product implements.
  Area? areaForProduct(String productId) {
    final product = products[productId];
    return product == null ? null : area(product.areaId);
  }

  /// The product implementing [areaId], when one exists.
  Product? productForArea(String areaId) {
    final id = area(areaId)?.productId;
    return id == null ? null : products[id];
  }

  ContentPack? contentFor(String productId, String locale) =>
      content['$productId.$locale'];

  /// The safeguards an area is bound by, resolved from its ids. An id with no
  /// matching safeguard is dropped rather than faked, and
  /// [unresolvedSafeguardIds] is what a test asserts is empty.
  List<Safeguard> safeguardsFor(Area area) => [
        for (final id in area.safeguardIds)
          if (safeguards[id] case final Safeguard safeguard) safeguard,
      ];

  /// Every capability token any safeguard names, in either direction.
  ///
  /// `crisis_routing_first` requires `crisis_card_pinned_first`;
  /// `slip_never_resets` forbids `streak_reset_on_lapse`. Both are capability
  /// names rather than safeguard ids, and this is the registry of them.
  Set<String> get capabilities => {
        for (final safeguard in safeguards.values) ...[
          ...safeguard.requires,
          ...safeguard.forbids,
        ],
      };

  /// The entries of [Archetype.requires] that name a safeguard.
  List<Safeguard> safeguardsRequiredBy(Archetype archetype) => [
        for (final id in archetype.requires)
          if (safeguards[id] case final Safeguard safeguard) safeguard,
      ];

  /// The entries of [Archetype.requires] that name a capability rather than a
  /// safeguard. Binding all the same — see [Archetype.requires].
  List<String> capabilitiesRequiredBy(Archetype archetype) => [
        for (final id in archetype.requires)
          if (!safeguards.containsKey(id)) id,
      ];

  /// Safeguard ids an *area* references that do not exist.
  ///
  /// Areas, unlike archetypes, list safeguard ids and nothing else, so this
  /// set being non-empty is a real fault in the bundle rather than a category
  /// confusion. `test/tether_bundle_test.dart` asserts it is empty.
  Set<String> get unresolvedSafeguardIds => {
        for (final area in areas)
          ...area.safeguardIds.where((id) => !safeguards.containsKey(id)),
      };

  /// Archetype ids an area declares that the shared library does not define.
  /// These are the proposed archetypes awaiting promotion, and the app has to
  /// render them as unbuilt rather than skip them silently.
  Set<String> get unpromotedArchetypeIds => {
        for (final area in areas) ...[
          ...area.sharedArchetypeIds.where((id) => !archetypes.containsKey(id)),
          ...area.specificArchetypes
              .map((proposed) => proposed.id)
              .where((id) => !archetypes.containsKey(id)),
        ],
        for (final product in products.values)
          ...product.screens
              .map((screen) => screen.archetypeId)
              .where((id) => !archetypes.containsKey(id)),
      };
}

// ---------------------------------------------------------------------------
// Parsing helpers
// ---------------------------------------------------------------------------

List<T> _list<T>(Object? raw, T Function(Map<String, Object?>) parse) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, Object?>>()
      .map(parse)
      .toList(growable: false);
}

List<String> _strings(Object? raw) {
  if (raw is! List) return const [];
  return raw.map((value) => '$value').toList(growable: false);
}

Set<int> _indices(Object? raw) {
  if (raw is! List) return const {};
  return {
    for (final value in raw)
      if (value is num) value.toInt(),
  };
}

/// Parses `[["4h 12m", "Average day"], …]`, the shape both `stats` and `rows`
/// use for their items.
List<(String, String)> _pairs(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final entry in raw)
      if (entry is List && entry.length >= 2) ('${entry[0]}', '${entry[1]}'),
  ];
}
