import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'design_bundle.dart';

/// Reads the design bundle out of `assets/design/`.
///
/// The files are copies of `files/tether-design.zip`, kept byte-identical so
/// that `tools/validate.py` in the bundle still validates what the app
/// actually ships. `test/tether_bundle_test.dart` asserts they have not
/// drifted apart; a copy nobody checks is a copy that is already stale.
abstract final class BundleLoader {
  /// Where the design JSON lives, relative to the package root.
  static const assetDirectory = 'assets/design';

  /// The area catalogue, the machinery, the constraints and the shell.
  static const _areas = '$assetDirectory/areas.json';
  static const _archetypes = '$assetDirectory/archetypes.json';
  static const _safeguards = '$assetDirectory/safeguards.json';
  static const _shell = '$assetDirectory/shell.json';

  /// The products that exist. Nine of the eleven areas have none, which is a
  /// fact about the programme rather than a gap in this list.
  static const productIds = <String>['breathefree', 'lookup'];

  /// The content packs that exist, as `<productId>.<locale>`. BreatheFree has
  /// no content file in the bundle — its 28 screens are approved artwork, not
  /// authored slots — so only LookUp appears here.
  static const contentKeys = <String>['lookup.en'];

  /// Archetypes proposed in this repository rather than shipped in the bundle.
  static const _supplementArchetypes =
      '$assetDirectory/supplement.archetypes.json';

  /// Content written in this repository to fill a gap, as
  /// `<productId>.<locale>`.
  static const supplementContentKeys = <String>['lookup.en'];

  /// Action-destination corrections. Never copy — see
  /// [ContentPack.withActionFix].
  static const _supplementNavigation =
      '$assetDirectory/supplement.navigation.json';

  /// Products written in this repository for areas the bundle left unbuilt.
  ///
  /// Nine of the eleven areas ship with `productId: null`, which is the
  /// catalogue saying "this is a plan". This file is how a plan becomes a
  /// programme without editing `areas.json`, which is a verbatim copy of the
  /// shipped bundle and is drift-tested against it.
  /// The areas this repository supplies a product for, one file each:
  /// `supplement.product.<areaId>.json`.
  ///
  /// A list rather than a directory scan, because an asset bundle has no
  /// readdir — and because a programme appearing in the app should be a line
  /// somebody added on purpose, not a file that happened to be copied in.
  static const supplementProductAreas = <String>[
    'metabolic',
    'cancer',
    'cardiovascular',
    'nutrition',
    'respiratory',
    'kidney_liver',
    'preventive',
    'aging',
  ];

  static String _supplementProductPath(String areaId) =>
      '$assetDirectory/supplement.product.$areaId.json';

  /// Parses the whole bundle. Called once at startup.
  ///
  /// Anything missing throws rather than yielding a half-built app: a screen
  /// list that silently lost its archetypes would render as a run of blank
  /// pages, and the failure would be found by a patient rather than by a test.
  static Future<DesignBundle> load({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;

    Future<Map<String, Object?>> read(String path) async {
      final raw = await assets.loadString(path);
      return jsonDecode(raw) as Map<String, Object?>;
    }

    final areasJson = await read(_areas);
    final archetypesJson = await read(_archetypes);
    final safeguardsJson = await read(_safeguards);
    final shellJson = await read(_shell);

    final products = <String, Product>{};
    for (final id in productIds) {
      final json = await read('$assetDirectory/product.$id.json');
      products[id] = Product.fromJson(json);
    }

    final content = <String, ContentPack>{};
    for (final key in contentKeys) {
      final json = await read('$assetDirectory/content.$key.json');
      content[key] = ContentPack.fromJson(json);
    }

    var areas = (areasJson['areas'] as List<Object?>? ?? const [])
        .whereType<Map<String, Object?>>()
        .map(Area.fromJson)
        .toList(growable: false);

    // Products written here, for areas the catalogue left as a plan.
    //
    // Loaded before content so that a supplement content pack has a product to
    // attach to. Only an area with no `productId` of its own can be claimed:
    // the bundle's two products win, and a supplement that tried to rebind
    // `tobacco` away from BreatheFree is ignored rather than honoured.
    final supplementProductJson = <Map<String, Object?>>[];
    for (final areaId in supplementProductAreas) {
      final json = await _readOptional(assets, _supplementProductPath(areaId));
      if (json != null) supplementProductJson.add(json);
    }

    for (final json in supplementProductJson) {
      final product = Product.fromJson(json);
      if (products.containsKey(product.id)) continue;

      final index = areas.indexWhere((area) => area.id == product.areaId);
      if (index == -1) continue;
      if (areas[index].productId != null) continue;

      products[product.id] = product;
      areas = [
        for (var i = 0; i < areas.length; i++)
          if (i == index)
            areas[i].withImplementation(
              productId: product.id,
              // An area with a programme somebody can join is not `planned`,
              // whatever the catalogue still says. The directory's whole
              // contract is being truthful about what exists, so the label has
              // to move with the implementation or the screen starts lying.
              status: json.containsKey(r'$areaStatus')
                  ? AreaStatus.parse(json[r'$areaStatus'])
                  : AreaStatus.inDevelopment,
            )
          else
            areas[i],
      ];
    }

    // The supplement is optional and loaded second, and a missing file is not
    // an error: the bundle alone is a valid, if incomplete, product. Only the
    // supplement tolerates being absent — see [_readOptional].
    for (final key in supplementContentKeys) {
      final json =
          await _readOptional(assets, '$assetDirectory/supplement.content.$key.json');
      if (json == null) continue;
      final pack = ContentPack.fromJson(
        json,
        provenance: ContentProvenance.supplement,
      );
      content[key] = content[key]?.fillGapsFrom(pack) ?? pack;
    }

    // Content for a product this repository added, discovered from the product
    // rather than from a list somebody has to remember to extend. A programme
    // with no content pack renders as its archetypes' slot lists, which is the
    // honest failure and not a crash.
    for (final json in supplementProductJson) {
      final productId = json['id'] as String?;
      if (productId == null) continue;
      for (final locale in _locales(json['locales'])) {
        final key = '$productId.$locale';
        if (content.containsKey(key)) continue;
        final packJson = await _readOptional(
          assets,
          '$assetDirectory/supplement.content.$key.json',
        );
        if (packJson == null) continue;
        content[key] = ContentPack.fromJson(
          packJson,
          provenance: ContentProvenance.supplement,
        );
      }
    }

    // Applied last, so a fix can point at a screen the supplement supplied.
    final navigation = await _readOptional(assets, _supplementNavigation);
    for (final fix in (navigation?['fixes'] as List<Object?>? ?? const [])
        .whereType<Map<String, Object?>>()) {
      final productId = fix['product'] as String?;
      final screenId = fix['screen'] as String?;
      final from = fix['from'] as String?;
      final to = fix['to'] as String?;
      final index = (fix['action'] as num?)?.toInt();
      if (productId == null ||
          screenId == null ||
          from == null ||
          to == null ||
          index == null) {
        continue;
      }

      for (final entry in content.entries.toList()) {
        if (entry.value.productId != productId) continue;
        content[entry.key] = entry.value.withActionFix(
          screenId: screenId,
          actionIndex: index,
          from: from,
          to: to,
        );
      }
    }

    final archetypes = {
      for (final json
          in (archetypesJson['archetypes'] as List<Object?>? ?? const [])
              .whereType<Map<String, Object?>>())
        json['id'] as String: Archetype.fromJson(json),
    };

    // Proposed archetypes fill gaps and never shadow the shared library, for
    // the same reason the content supplement does not: the library is the
    // thing eleven areas share, and a local override would quietly fork it.
    final supplementArchetypes = await _readOptional(assets, _supplementArchetypes);
    for (final json
        in (supplementArchetypes?['archetypes'] as List<Object?>? ?? const [])
            .whereType<Map<String, Object?>>()) {
      final id = json['id'] as String;
      if (archetypes.containsKey(id)) continue;
      archetypes[id] = Archetype.fromJson(
        json,
        provenance: ContentProvenance.supplement,
      );
    }

    final safeguards = {
      for (final json
          in (safeguardsJson['safeguards'] as List<Object?>? ?? const [])
              .whereType<Map<String, Object?>>())
        json['id'] as String: Safeguard.fromJson(json),
    };

    return DesignBundle(
      areas: areas,
      archetypes: archetypes,
      safeguards: safeguards,
      shell: ShellSpec.fromJson(shellJson),
      products: products,
      content: content,
    );
  }

  /// The locales a product declares, defaulting to English.
  ///
  /// Values are stringified rather than cast, because a locale arriving as
  /// anything but a string is a malformed product file and an empty list of
  /// locales would silently cost that programme its entire content pack — the
  /// failure would look like "the screens are unwritten" rather than "the file
  /// is wrong", which is a much longer afternoon.
  static List<String> _locales(Object? raw) => raw is List && raw.isNotEmpty
      ? raw.map((value) => value.toString()).toList(growable: false)
      : const <String>['en'];

  /// Reads an asset that is allowed not to exist.
  ///
  /// Used only for the supplement. The bundle's own files throw when missing,
  /// because an app with no areas file is not a degraded app, it is a blank
  /// one — see [load].
  ///
  /// Only the *read* is inside the try. Decoding happens after it, so a
  /// supplement that exists but is malformed still throws: "the file is not
  /// there" and "the file is broken" are different problems and only the first
  /// one is allowed to pass quietly. The exception type is not narrowed
  /// because it differs by bundle implementation — a `FlutterError` from the
  /// asset manifest, a `FileSystemException` from the disk-backed bundle the
  /// tests use — and naming the second would pull `dart:io` into a library
  /// that has to compile for web.
  static Future<Map<String, Object?>?> _readOptional(
    AssetBundle assets,
    String path,
  ) async {
    final String raw;
    try {
      raw = await assets.loadString(path);
    } catch (_) {
      return null;
    }
    return jsonDecode(raw) as Map<String, Object?>;
  }
}
